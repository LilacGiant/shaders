/*
MIT License

Copyright (c) 2020 DarthShader

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#region
#if VRC_SDK_VRCSDK3
#endif
#if VRC_SDK_VRCSDK2
using VRCSDK2;
#endif
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;
#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
using VRC.SDKBase.Editor.BuildPipeline;
#endif
#endregion


namespace z3y
{

#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
    public class LockMaterialsOnVRCWorldUpload : IVRCSDKBuildRequestedCallback
    {
        public int callbackOrder => 69;

        bool IVRCSDKBuildRequestedCallback.OnBuildRequested(VRCSDKRequestedBuildType requestedBuildType)
        {
            #if !UNITY_ANDROID
                ShaderOptimizer.LockAllMaterials();
            #endif
            return true;
        }
    }
#endif

    public class OnShaderPreprocess : IPreprocessShaders
    {
        public int callbackOrder => 69;

        public void OnProcessShader(Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> data)
        {
            bool shouldStrip = ShaderOptimizer.IsShaderUsingOptimizer(shader) && !shader.name.StartsWith("Hidden/");

            for (int i = data.Count - 1; i >= 0; --i)
            {
                if (shouldStrip) data.RemoveAt(i);
            }
        }
    }

    public class UnlockOnPlatformChange : IActiveBuildTargetChanged
    {
        public int callbackOrder { get { return 69; } }
        public void OnActiveBuildTargetChanged(BuildTarget previousTarget, BuildTarget newTarget)
        {
            ShaderOptimizer.UnlockAllMaterials();
        }
    }

    // Static methods to generate new shader files with in-place constants based on a material's properties
    // and link that new shader to the material automatically
    public class ShaderOptimizer
    {
        // For some reason, 'if' statements with replaced constant (literal) conditions cause some compilation error
        // So until that is figured out, branches will be removed by default
        // Set to false if you want to keep UNITY_BRANCH and [branch]
        private static bool RemoveUnityBranches = true;

        // LOD Crossfade Dithing doesn't have multi_compile keyword correctly toggled at build time (its always included) so
        // this hard-coded material property will uncomment //#pragma multi_compile _ LOD_FADE_CROSSFADE in optimized .shader files
        private static readonly string LODCrossFadePropertyName = "_LodCrossFade";
        
        // Material property suffix that controls whether the property of the same name gets baked into the optimized shader
        // e.g. if _Color exists and _ColorAnimated = 1, _Color will not be baked in
        private static readonly string AnimatedPropertySuffix = "Animated";

        private static readonly string OriginalShaderTag = "OriginalShaderTag";
        private static readonly string ShaderOptimizerEnabled = "wAg6H2wQzc7UbxaL";

        // Material properties are put into each CGPROGRAM as preprocessor defines when the optimizer is run.
        // This is mainly targeted at culling interpolators and lines that rely on those interpolators.
        // (The compiler is not smart enough to cull VS output that isn't used anywhere in the PS)
        // Additionally, simply enabling the optimizer can define a keyword, whose name is stored here.
        // This keyword is added to the beginning of all passes, right after CGPROGRAM
        private static readonly string OptimizerEnabledKeyword = "OPTIMIZER_ENABLED";

        private static readonly bool ReplaceAnimatedParameters = false;
        
        public static void LockMaterial(Material mat, bool applyLater, Material sharedMaterial)
        {
            mat.SetFloat(ShaderOptimizerEnabled, 1);
            MaterialProperty[] props = MaterialEditor.GetMaterialProperties(new Object[] { mat });
            if (!Lock(mat, props, applyLater, sharedMaterial)) // Error locking shader, revert property
                mat.SetFloat(ShaderOptimizerEnabled, 0);
        }

        [MenuItem("Tools/Shader Optimizer/Unlock Materials In Scene")]
        public static void UnlockAllMaterials()
        {
            Material[] mats = GetMaterialsUsingOptimizer(true);

            foreach (Material m in mats)
            {
                Unlock(m);
                m.SetFloat(ShaderOptimizerEnabled, 0);
            }
        }

        private static readonly string[] PropertiesToSkip = {
            ShaderOptimizerEnabled,
            "_BlendOp",
            "_BlendOpAlpha",
            "_SrcBlend",
            "_DstBlend",
            "_ZWrite",
            "_ZTest",
            "_Cull"
        };

        public static readonly string[] TexelSizeCheck = {
            "_RNM0",
            "_RNM1",
            "_RNM2"
        };
        
        [MenuItem("Tools/Shader Optimizer/Lock Materials In Scene")]
        public static void LockAllMaterials()
        {
            Material[] mats = GetMaterialsUsingOptimizer(false);
            float progress = mats.Length;

            if(progress == 0) return;
            
            AssetDatabase.StartAssetEditing();
            Dictionary<string, Material> MaterialsPropertyHash = new Dictionary<string, Material>();

            for (int i=0; i<progress; i++)
            {
                EditorUtility.DisplayCancelableProgressBar("Generating Shaders", mats[i].name, i/progress);

                int propCount = ShaderUtil.GetPropertyCount(mats[i].shader);
                StringBuilder materialPropertyValues = new StringBuilder(mats[i].shader.name);

                for(int l=0; l<propCount; l++)
                {
                    string propName = ShaderUtil.GetPropertyName(mats[i].shader, l);
                    
                    if(PropertiesToSkip.Contains(propName))
                    {
                        materialPropertyValues.Append(propName);
                        continue;
                    }

                    bool isAnimated = !mats[i].GetTag(propName, false).Equals(string.Empty, StringComparison.Ordinal);

                    if(isAnimated)
                    {
                        materialPropertyValues.Append($"{propName}_Animated");
                        continue;
                    }
                    
                    switch(ShaderUtil.GetPropertyType(mats[i].shader, l))
                    {
                        case(ShaderUtil.ShaderPropertyType.Float):
                            materialPropertyValues.Append(mats[i].GetFloat(propName));
                            break;

                        case(ShaderUtil.ShaderPropertyType.TexEnv):
                            Texture t = mats[i].GetTexture(propName);
                            Vector4 texelSize = new Vector4(1.0f, 1.0f, 1.0f, 1.0f);
                            
                            materialPropertyValues.Append(t is null ? "false" : "true");
                            materialPropertyValues.Append(mats[i].GetTextureOffset(propName));
                            materialPropertyValues.Append(mats[i].GetTextureScale(propName));

                            if (t != null && TexelSizeCheck.Contains(propName)) texelSize = new Vector4(1.0f / t.width, 1.0f / t.height, t.width, t.height);
                            materialPropertyValues.Append(texelSize);
                            break;

                        case(ShaderUtil.ShaderPropertyType.Color):
                            materialPropertyValues.Append(mats[i].GetColor(propName));
                            break;

                        case(ShaderUtil.ShaderPropertyType.Range):
                            materialPropertyValues.Append(mats[i].GetFloat(propName));
                            break;

                        case(ShaderUtil.ShaderPropertyType.Vector):
                            materialPropertyValues.Append(mats[i].GetVector(propName));
                            break;
                    }
                }

                Material sharedMaterial = null;
                string propertyKeys = materialPropertyValues.ToString();
                if (MaterialsPropertyHash.ContainsKey(propertyKeys))
                {
                    MaterialsPropertyHash.TryGetValue(propertyKeys, out sharedMaterial);
                }
                else
                {
                    MaterialsPropertyHash.Add(propertyKeys, mats[i]);
                }
                
                LockMaterial(mats[i], true, sharedMaterial);
            }
            
            EditorUtility.ClearProgressBar();
            AssetDatabase.StopAssetEditing();
            AssetDatabase.Refresh();

            for (int i=0; i<progress; i++)
            {
                EditorUtility.DisplayCancelableProgressBar("Replacing Shaders", mats[i].name, i/progress);
                LockApplyShader(mats[i]);
            }
            EditorUtility.ClearProgressBar();
            
        }

        public static Material[] GetMaterialsUsingOptimizer(bool isLocked)
        {
            List<Material> materials = new List<Material>();
            List<Material> foundMaterials = new List<Material>();
            Scene scene = SceneManager.GetActiveScene();

            string[] materialPaths = AssetDatabase.GetDependencies(scene.path).Where(x => x.EndsWith(".mat")).ToArray();
            var renderers = Object.FindObjectsOfType<Renderer>();

            foreach (var t in materialPaths)
            {
                Material mat = AssetDatabase.LoadAssetAtPath<Material>(t);
                foundMaterials.Add(mat);
            }

            for (int i = 0; i < renderers?.Length; i++)
            {
                for (int j = 0; j < renderers[i].sharedMaterials?.Length; j++)
                {
                    foundMaterials.Add(renderers[i].sharedMaterials[j]);
                }
            }

            foreach (Material mat in foundMaterials)
            {
                if(mat is null) continue;
                if(!mat.shader.name.Equals("Hidden/InternalErrorShader"))
                {
                    if(!materials.Contains(mat) && IsShaderUsingOptimizer(mat.shader))
                        if(mat.GetFloat(ShaderOptimizerEnabled) == (isLocked ? 1 : 0))
                            materials.Add(mat);
                }
                else
                {
                    if(!materials.Contains(mat) && !mat.GetTag(OriginalShaderTag, false).Equals(string.Empty))
                        if(isLocked)
                            materials.Add(mat);
                }
            }
            return materials.Distinct().ToArray();
        }

        public static bool IsShaderUsingOptimizer(Shader shader)
        {
            bool a = false;
            try 
            {
                a = ShaderUtil.GetPropertyName(shader, 0) == ShaderOptimizerEnabled;
            }
            catch
            {
                // ignored
            }

            return a;
        }

        // Would be better to dynamically parse the "C:\Program Files\UnityXXXX\Editor\Data\CGIncludes\" folder
        // to get version specific includes but eh
        private static readonly string[] DefaultUnityShaderIncludes = {
            "UnityUI.cginc",
            "AutoLight.cginc",
            "GLSLSupport.glslinc",
            "HLSLSupport.cginc",
            "Lighting.cginc",
            "SpeedTreeBillboardCommon.cginc",
            "SpeedTreeCommon.cginc",
            "SpeedTreeVertex.cginc",
            "SpeedTreeWind.cginc",
            "TerrainEngine.cginc",
            "TerrainSplatmapCommon.cginc",
            "Tessellation.cginc",
            "UnityBuiltin2xTreeLibrary.cginc",
            "UnityBuiltin3xTreeLibrary.cginc",
            "UnityCG.cginc",
            "UnityCG.glslinc",
            "UnityCustomRenderTexture.cginc",
            "UnityDeferredLibrary.cginc",
            "UnityDeprecated.cginc",
            "UnityGBuffer.cginc",
            "UnityGlobalIllumination.cginc",
            "UnityImageBasedLighting.cginc",
            "UnityInstancing.cginc",
            "UnityLightingCommon.cginc",
            "UnityMetaPass.cginc",
            "UnityPBSLighting.cginc",
            "UnityShaderUtilities.cginc",
            "UnityShaderVariables.cginc",
            "UnityShadowLibrary.cginc",
            "UnitySprites.cginc",
            "UnityStandardBRDF.cginc",
            "UnityStandardConfig.cginc",
            "UnityStandardCore.cginc",
            "UnityStandardCoreForward.cginc",
            "UnityStandardCoreForwardSimple.cginc",
            "UnityStandardInput.cginc",
            "UnityStandardMeta.cginc",
            "UnityStandardParticleInstancing.cginc",
            "UnityStandardParticles.cginc",
            "UnityStandardParticleShadow.cginc",
            "UnityStandardShadow.cginc",
            "UnityStandardUtils.cginc"
        };

        private static readonly char[] ValidSeparators = {' ','\t','\r','\n',';',',','.','(',')','[',']','{','}','>','<','=','!','&','|','^','+','-','*','/','#','?' };

        private static readonly string[] ValidPropertyDataTypes = {
            "float",
            "float2",
            "float3",
            "float4",
            "half",
            "half2",
            "half3",
            "half4",
            "fixed",
            "fixed2",
            "fixed3",
            "fixed4",
            "int",
            "uint",
            "double"
        };

        public enum PropertyType
        {
            Vector,
            Float
        }

        private class PropertyData
        {
            public PropertyType type;
            public string name;
            public Vector4 value;
        }

        private class Macro
        {
            public string name;
            public string[] args;
            public string contents;
        }

        private class ParsedShaderFile
        {
            public string filePath;
            public string[] lines;
        }

        public static bool Lock(Material material, MaterialProperty[] props)
        {
            Lock(material, props, false, null);
            return true;
        }

        private static bool Lock(Material material, MaterialProperty[] props, bool applyShaderLater, Material sharedMaterial)
        {
 
            Shader shader = material.shader;
            string shaderFilePath = AssetDatabase.GetAssetPath(shader);
            string smallguid = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(material));
            string newShaderName = $"Hidden/{shader.name}/{smallguid}";
            string newShaderDirectory = $"Assets/OptimizedShaders/{smallguid}/";
            string newShaderPath = $"{newShaderDirectory}{Path.GetFileName(shaderFilePath)}";
            ReplaceStruct replaceStruct = new ReplaceStruct();
            
            
            if(!(sharedMaterial is null))
            {
                replaceStruct.Material = material;
                replaceStruct.Shader = sharedMaterial.shader;
                replaceStruct.SmallGuid = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(sharedMaterial));
                replaceStruct.NewShaderPath = $"Assets/OptimizedShaders/{replaceStruct.SmallGuid}/{Path.GetFileName(AssetDatabase.GetAssetPath(sharedMaterial.shader))}";
                ReplaceStructs.Add(material, replaceStruct);
                return true;

            }


            // Get collection of all properties to replace
            // Simultaneously build a string of #defines for each CGPROGRAM
            StringBuilder definesSB = new StringBuilder();
            // Append convention OPTIMIZER_ENABLED keyword
            definesSB.Append(Environment.NewLine);
            definesSB.Append("#define ");
            definesSB.Append(OptimizerEnabledKeyword);
            definesSB.Append(Environment.NewLine);
            // Append all keywords active on the material
            foreach (string keyword in material.shaderKeywords)
            {
                if (keyword.Equals(string.Empty)) continue; // idk why but null keywords exist if _ keyword is used and not removed by the editor at some point
                definesSB.Append("#define ");
                definesSB.Append(keyword);
                definesSB.Append(Environment.NewLine);
            }

            List<PropertyData> constantProps = new List<PropertyData>();
            List<string> animatedProps = new List<string>();


            foreach (MaterialProperty prop in props)
            {
                if (prop is null) continue;

                // Every property gets turned into a preprocessor variable
                switch(prop.type)
                {
                    case MaterialProperty.PropType.Float:
                    case MaterialProperty.PropType.Range:
                        definesSB.Append("#define PROP");
                        definesSB.Append(prop.name.ToUpper());
                        definesSB.Append(' ');
                        definesSB.Append(prop.floatValue.ToString(CultureInfo.InvariantCulture));
                        definesSB.Append(Environment.NewLine);
                        break;
                    case MaterialProperty.PropType.Texture:
                        if (prop.textureValue != null)
                        {
                            definesSB.Append("#define PROP");
                            definesSB.Append(prop.name.ToUpper());
                            definesSB.Append(Environment.NewLine);
                        }
                        break;
                }

                if (
                  prop.name.EndsWith(AnimatedPropertySuffix) ||
                 (!material.GetTag(prop.name + AnimatedPropertySuffix, false).Equals(string.Empty)))
                    continue;


                // Check for the convention 'Animated' Property to be true otherwise assume all properties are constant
                // nlogn trash
                MaterialProperty animatedProp = Array.Find(props, x => x.name == prop.name + AnimatedPropertySuffix);
                if (animatedProp != null && animatedProp.floatValue == 1)
                {
                    animatedProps.Add(prop.name);
                    continue;
                }

                PropertyData propData;
                switch(prop.type)
                {
                    case MaterialProperty.PropType.Color:
                        propData = new PropertyData();
                        propData.type = PropertyType.Vector;
                        propData.name = prop.name;
                        if ((prop.flags & MaterialProperty.PropFlags.HDR) != 0)
                        {
                            if ((prop.flags & MaterialProperty.PropFlags.Gamma) != 0)
                                propData.value = prop.colorValue.linear;
                            else propData.value = prop.colorValue;
                        }
                        else if ((prop.flags & MaterialProperty.PropFlags.Gamma) != 0)
                            propData.value = prop.colorValue;
                        else propData.value = prop.colorValue.linear;
                        constantProps.Add(propData);
                        break;
                    case MaterialProperty.PropType.Vector:
                        propData = new PropertyData();
                        propData.type = PropertyType.Vector;
                        propData.name = prop.name;
                        propData.value = prop.vectorValue;
                        constantProps.Add(propData);
                        break;
                    case MaterialProperty.PropType.Float:
                    case MaterialProperty.PropType.Range:
                        propData = new PropertyData();
                        propData.type = PropertyType.Float;
                        propData.name = prop.name;
                        propData.value = new Vector4(prop.floatValue, 0, 0, 0);
                        constantProps.Add(propData);
                        break;
                    case MaterialProperty.PropType.Texture:
                        animatedProp = Array.Find(props, x => x.name == prop.name + "_ST" + AnimatedPropertySuffix);
                        if (!(animatedProp != null && animatedProp.floatValue == 1))
                        {
                            PropertyData ST = new PropertyData();
                            ST.type = PropertyType.Vector;
                            ST.name = prop.name + "_ST";
                            Vector2 offset = material.GetTextureOffset(prop.name);
                            Vector2 scale = material.GetTextureScale(prop.name);
                            ST.value = new Vector4(scale.x, scale.y, offset.x, offset.y);
                            constantProps.Add(ST);
                        }
                        animatedProp = Array.Find(props, x => x.name == prop.name + "_TexelSize" + AnimatedPropertySuffix);
                        if (!(animatedProp != null && animatedProp.floatValue == 1))
                        {
                            PropertyData TexelSize = new PropertyData();
                            TexelSize.type = PropertyType.Vector;
                            TexelSize.name = prop.name + "_TexelSize";
                            Texture t = prop.textureValue;
                            if (t != null)
                                TexelSize.value = new Vector4(1.0f / t.width, 1.0f / t.height, t.width, t.height);
                            else TexelSize.value = new Vector4(1.0f, 1.0f, 1.0f, 1.0f);
                            constantProps.Add(TexelSize);
                        }
                        break;
                }
            }
            string optimizerDefines = definesSB.ToString();
                
            // Parse shader and cginc files, also gets preprocessor macros
            List<ParsedShaderFile> shaderFiles = new List<ParsedShaderFile>();
            List<Macro> macros = new List<Macro>();
            if (!ParseShaderFilesRecursive(shaderFiles, newShaderDirectory, shaderFilePath, macros, material))
                return false;
            

            // Loop back through and do macros, props, and all other things line by line as to save string ops
            // Will still be a massive n2 operation from each line * each property
            foreach (ParsedShaderFile psf in shaderFiles)
            {
                // Shader file specific stuff
                if (psf.filePath.EndsWith(".shader"))
                {
                    for (int i=0; i<psf.lines.Length;i++)
                    {
                        string trimmedLine = psf.lines[i].TrimStart();
                        if (trimmedLine.StartsWith("Shader"))
                        {
                            string originalSgaderName = psf.lines[i].Split('\"')[1];
                            psf.lines[i] = psf.lines[i].Replace(originalSgaderName, newShaderName);
                        }
                        else if (trimmedLine.StartsWith("#pragma multi_compile _ LOD_FADE_CROSSFADE"))
                        {
                            MaterialProperty crossfadeProp = Array.Find(props, x => x.name == LODCrossFadePropertyName);
                            if (crossfadeProp != null && crossfadeProp.floatValue == 0)
                                psf.lines[i] = psf.lines[i].Replace("#pragma", "//#pragma");
                        }
           
                        else if (trimmedLine.StartsWith("CGINCLUDE"))
                        {
                            for (int j=i+1; j<psf.lines.Length;j++)
                                if (psf.lines[j].TrimStart().StartsWith("ENDCG"))
                                {
                                    ReplaceShaderValues(material, psf.lines, i+1, j, constantProps, animatedProps, macros);
                                    break;
                                }
                        }
                        else if (trimmedLine.StartsWith("SubShader"))
                        {
                            psf.lines[i-1] += "CGINCLUDE";
                            psf.lines[i-1] += optimizerDefines;
                            psf.lines[i-1] += "ENDCG";
                        }
                        else if (trimmedLine.StartsWith("CGPROGRAM"))
                        {
                            for (int j=i+1; j<psf.lines.Length;j++)
                                if (psf.lines[j].TrimStart().StartsWith("ENDCG"))
                                {
                                    ReplaceShaderValues(material, psf.lines, i+1, j, constantProps, animatedProps, macros);
                                    break;
                                }
                        }

                        else if (ReplaceAnimatedParameters)
                        {
                            // Check to see if line contains an animated property name with valid left/right characters
                            // then replace the parameter name with prefixtag + parameter name
                            string animatedPropName = animatedProps.Find(x => trimmedLine.Contains(x));
                            if (animatedPropName != null)
                            {
                                int parameterIndex = trimmedLine.IndexOf(animatedPropName, StringComparison.Ordinal);
                                char charLeft = trimmedLine[parameterIndex-1];
                                char charRight = trimmedLine[parameterIndex + animatedPropName.Length];
                                if (Array.Exists(ValidSeparators, x => x == charLeft) && Array.Exists(ValidSeparators, x => x == charRight))
                                    psf.lines[i] = psf.lines[i].Replace(animatedPropName, animatedPropName + material.GetTag("AnimatedParametersSuffix", false, string.Empty));
                            }
                        }
                    }
                }
                else // CGINC file
                    ReplaceShaderValues(material, psf.lines, 0, psf.lines.Length, constantProps, animatedProps, macros);

                // Recombine file lines into a single string
                int totalLen = psf.lines.Length*2; // extra space for newline chars
                foreach (string line in psf.lines)
                    totalLen += line.Length;
                StringBuilder sb = new StringBuilder(totalLen);
                // This appendLine function is incompatible with the '\n's that are being added elsewhere
                foreach (string line in psf.lines)
                    sb.AppendLine(line);
                string output = sb.ToString();

                // Write output to file
                string newDirectory = psf.filePath.Split('/').Last();

                new FileInfo(newShaderDirectory + newDirectory).Directory.Create();
                try
                {
                    StreamWriter sw = new StreamWriter(newShaderDirectory + newDirectory);
                    sw.Write(output);
                    sw.Close();
                }
                catch (IOException e)
                {
                    Debug.LogError("[Kaj Shader Optimizer] Processed shader file " + newShaderDirectory + newDirectory + " could not be written.  " + e);
                    return false;
                }
            }
            

            replaceStruct.Material = material;
            replaceStruct.Shader = shader;
            replaceStruct.SmallGuid = smallguid;
            replaceStruct.NewShaderPath = newShaderPath;

            if (applyShaderLater)
            {
                ReplaceStructs.Add(material, replaceStruct);
                return true;
            }

            AssetDatabase.Refresh();

            return ReplaceShader(replaceStruct);
        }

        private static readonly Dictionary<Material, ReplaceStruct> ReplaceStructs = new Dictionary<Material, ReplaceStruct>();

        private struct ReplaceStruct
        {
            public Material Material;
            public Shader Shader;
            public string SmallGuid;
            public string NewShaderPath;
        }

        private static void LockApplyShader(Material material)
        {
            if (ReplaceStructs.ContainsKey(material) == false) return;
            ReplaceStruct applyStruct = ReplaceStructs[material];
            ReplaceStructs.Remove(material);
            ReplaceShader(applyStruct);
        }


        private static bool ReplaceShader(ReplaceStruct replaceStruct)
        {

            // Write original shader to override tag
            replaceStruct.Material.SetOverrideTag(OriginalShaderTag, replaceStruct.Shader.name);
            // Write the new shader folder name in an override tag so it will be deleted 
            replaceStruct.Material.SetOverrideTag("OptimizedShaderFolder", replaceStruct.SmallGuid);

            // For some reason when shaders are swapped on a material the RenderType override tag gets completely deleted and render queue set back to -1
            // So these are saved as temp values and reassigned after switching shaders
            string renderType = replaceStruct.Material.GetTag("RenderType", false, string.Empty);
            int renderQueue = replaceStruct.Material.renderQueue;

            // Actually switch the shader
            // Shader newShader = Shader.Find(applyLater.newShaderName);
            Shader newShader = AssetDatabase.LoadAssetAtPath<Shader>(replaceStruct.NewShaderPath);
            
            if (newShader is null)
            {
               // LockMaterial(applyLater.material, false, null);
                Debug.LogError("[Kaj Shader Optimizer] Generated shader " + replaceStruct.NewShaderPath + " for " + replaceStruct.Material +" could not be found ");
                return false;
            }
            replaceStruct.Material.shader = newShader;
            replaceStruct.Material.SetOverrideTag("RenderType", renderType);
            replaceStruct.Material.renderQueue = renderQueue;

            // Remove ALL keywords
            foreach (string keyword in replaceStruct.Material.shaderKeywords)
                replaceStruct.Material.DisableKeyword(keyword);

            return true;
        }


        // Preprocess each file for macros and includes
        // Save each file as string[], parse each macro with //KSOEvaluateMacro
        // Only editing done is replacing #include "X" filepaths where necessary
        // most of these args could be private static members of the class
        private static bool ParseShaderFilesRecursive(List<ParsedShaderFile> filesParsed, string newTopLevelDirectory, string filePath, List<Macro> macros, Material mat)
        {
            // Infinite recursion check
            if (filesParsed.Exists(x => x.filePath == filePath)) return true;

            ParsedShaderFile psf = new ParsedShaderFile();
            psf.filePath = filePath;
            filesParsed.Add(psf);

            // Read file
            string fileContents;
            try
            {
                StreamReader sr = new StreamReader(filePath);
                fileContents = sr.ReadToEnd();
                sr.Close();
            }
            catch (FileNotFoundException e)
            {
                Debug.LogError("[Kaj Shader Optimizer] Shader file " + filePath + " not found.  " + e);
                return false;
            }
            catch (IOException e)
            {
                Debug.LogError("[Kaj Shader Optimizer] Error reading shader file.  " + e);
                return false;
            }

            // Parse file line by line
            List<string> macrosList = new List<string>();
            string[] fileLines = Regex.Split(fileContents, "\r\n|\r|\n");
            for (int i=0; i<fileLines.Length; i++)
            {
                string lineParsed = fileLines[i].TrimStart();

                // Skip the cginc
                if (lineParsed.StartsWith("//#if") && mat != null)
                {
                    string[] materialProperties = Regex.Split(lineParsed.Replace("//#if", ""), ",");
                    try
                    {
                        bool all = true;
                        foreach (var x in materialProperties)
                        {
                            if (mat.GetFloat(x) != 0)
                            {
                                all = false;
                                break;
                            }
                        }
                        if(all)
                        {
                            i++;
                            fileLines[i] = fileLines[i].Insert(0, "//");
                        }
                    }
                    catch
                    {
                        Debug.LogError($"Property at line {i} not found on {mat}");
                    }
                }

                // Specifically requires no whitespace between # and include, as it should be
                else if (lineParsed.StartsWith("#include"))
                {
                    int firstQuotation = lineParsed.IndexOf('\"',0);
                    int lastQuotation = lineParsed.IndexOf('\"',firstQuotation+1);
                    string includeFilename = lineParsed.Substring(firstQuotation+1, lastQuotation-firstQuotation-1);

                    // Skip default includes
                    if (Array.Exists(DefaultUnityShaderIncludes, x => x.Equals(includeFilename, StringComparison.InvariantCultureIgnoreCase)))
                        continue;

                    // cginclude filepath is either absolute or relative
                    if (includeFilename.StartsWith("Assets/"))
                    {
                        if (!ParseShaderFilesRecursive(filesParsed, newTopLevelDirectory, includeFilename, macros, mat))
                            return false;
                        // Only absolute filepaths need to be renampped in-file
                        fileLines[i] = fileLines[i].Replace(includeFilename, newTopLevelDirectory + includeFilename);
                    }
                    else
                    {
                        string includeFullpath = GetFullPath(includeFilename, Path.GetDirectoryName(filePath));
                        if (!ParseShaderFilesRecursive(filesParsed, newTopLevelDirectory, includeFullpath, macros, mat))
                            return false;
                    }
                }
            }

            // Prepare the macros list into pattern matchable structs
            // Revise this later to not do so many string ops
            foreach (string macroString in macrosList)
            {
                string m = macroString;
                Macro macro = new Macro();
                m = m.TrimStart();
                if (m[0] != '#') continue;
                m = m.Remove(0, "#".Length).TrimStart();
                if (!m.StartsWith("define")) continue;
                m = m.Remove(0, "define".Length).TrimStart();
                int firstParenthesis = m.IndexOf('(');
                macro.name = m.Substring(0, firstParenthesis);
                m = m.Remove(0, firstParenthesis + "(".Length);
                int lastParenthesis = m.IndexOf(')');
                string allArgs = m.Substring(0, lastParenthesis).Replace(" ", "").Replace("\t", "");
                macro.args = allArgs.Split(',');
                m = m.Remove(0, lastParenthesis + ")".Length);
                macro.contents = m;
                macros.Add(macro);
            }

            // Save psf lines to list
            psf.lines = fileLines;
            return true;
        }

        // error CS1501: No overload for method 'Path.GetFullPath' takes 2 arguments
        // Thanks Unity
        // Could be made more efficent with stringbuilder
        public static string GetFullPath(string relativePath, string basePath)
        {
            while (relativePath.StartsWith("./"))
                relativePath = relativePath.Remove(0, "./".Length);
            while (relativePath.StartsWith("../"))
            {
                basePath = basePath.Remove(basePath.LastIndexOf(Path.DirectorySeparatorChar), basePath.Length - basePath.LastIndexOf(Path.DirectorySeparatorChar));
                relativePath = relativePath.Remove(0, "../".Length);
            }
            return basePath + '/' + relativePath;
        }
 
        // Replace properties! The meat of the shader optimization process
        // For each constantProp, pattern match and find each instance of the property that isn't a declaration
        // most of these args could be private static members of the class
        private static void ReplaceShaderValues(Material material, string[] lines, int startLine, int endLine, List<PropertyData> constants, List<string> animProps, List<Macro> macros)
        {

            for (int i=startLine;i<endLine;i++)
            {
                string lineTrimmed = lines[i].TrimStart();
                // Remove all shader_feature directives
                if (lineTrimmed.StartsWith("#pragma shader_feature") || lineTrimmed.StartsWith("#pragma shader_feature_local"))
                    lines[i] = "//" + lines[i];
                

                // then replace macros
                foreach (Macro macro in macros)
                {
                    // Expects only one instance of a macro per line!
                    int macroIndex;
                    if ((macroIndex = lines[i].IndexOf(macro.name + "(", StringComparison.Ordinal)) != -1)
                    {
                        // Macro exists on this line, make sure its not the definition
                        string lineParsed = lineTrimmed.Replace(" ", "").Replace("\t", "");
                        if (lineParsed.StartsWith("#define")) continue;

                        // parse args between first '(' and first ')'
                        int firstParenthesis = macroIndex + macro.name.Length;
                        int lastParenthesis = lines[i].IndexOf(')', macroIndex + macro.name.Length+1);
                        string allArgs = lines[i].Substring(firstParenthesis+1, lastParenthesis-firstParenthesis-1);
                        string[] args = allArgs.Split(',');

                        // Replace macro parts
                        string newContents = macro.contents;
                        for (int j=0; j<args.Length;j++)
                        {
                            args[j] = args[j].Trim();
                            int argIndex;
                            int lastIndex = 0;
                            // ERROR: This method of one-by-one argument replacement will infinitely loop
                            // if one of the arguments to paste into the macro definition has the same name
                            // as one of the macro arguments!
                            while ((argIndex = newContents.IndexOf(macro.args[j], lastIndex, StringComparison.Ordinal)) != -1)
                            {
                                lastIndex = argIndex+1;
                                char charLeft = ' ';
                                if (argIndex-1 >= 0)
                                    charLeft = newContents[argIndex-1];
                                char charRight = ' ';
                                if (argIndex+macro.args[j].Length < newContents.Length)
                                    charRight = newContents[argIndex+macro.args[j].Length];
                                if (Array.Exists(ValidSeparators, x => x == charLeft) && Array.Exists(ValidSeparators, x => x == charRight))
                                {
                                    // Replcae the arg!
                                    StringBuilder sbm = new StringBuilder(newContents.Length - macro.args[j].Length + args[j].Length);
                                    sbm.Append(newContents, 0, argIndex);
                                    sbm.Append(args[j]);
                                    sbm.Append(newContents, argIndex + macro.args[j].Length, newContents.Length - argIndex - macro.args[j].Length);
                                    newContents = sbm.ToString();
                                }
                            }
                        }

                        newContents = newContents.Replace("##", ""); // Remove token pasting separators
                        // Replace the line with the evaluated macro
                        StringBuilder sb = new StringBuilder(lines[i].Length + newContents.Length);
                        sb.Append(lines[i], 0, macroIndex);
                        sb.Append(newContents);
                        sb.Append(lines[i], lastParenthesis+1, lines[i].Length - lastParenthesis-1);
                        //lines[i] = sb.ToString();
                    }
                }
                
                // then replace properties
                foreach (PropertyData constant in constants)
                {
                    int constantIndex;
                    int lastIndex = 0;
                    bool declarationFound = false;
                    while ((constantIndex = lines[i].IndexOf(constant.name, lastIndex, StringComparison.Ordinal)) != -1)
                    {
                        lastIndex = constantIndex+1;
                        char charLeft = ' ';
                        if (constantIndex-1 >= 0)
                            charLeft = lines[i][constantIndex-1];
                        char charRight = ' ';
                        if (constantIndex + constant.name.Length < lines[i].Length)
                            charRight = lines[i][constantIndex + constant.name.Length];
                        // Skip invalid matches (probably a subname of another symbol)
                        if (!(Array.Exists(ValidSeparators, x => x == charLeft) && Array.Exists(ValidSeparators, x => x == charRight)))
                            continue;
                        
                        // Skip basic declarations of unity shader properties i.e. "uniform float4 _Color;"
                        if (!declarationFound)
                        {
                            string precedingText = lines[i].Substring(0, constantIndex-1).TrimEnd(); // whitespace removed string immediately to the left should be float or float4
                            string restOftheFile = lines[i].Substring(constantIndex + constant.name.Length).TrimStart(); // whitespace removed character immediately to the right should be ;
                            if (Array.Exists(ValidPropertyDataTypes, x => precedingText.EndsWith(x)) && restOftheFile.StartsWith(";"))
                            {
                                declarationFound = true;
                                continue;
                            }
                        }

                        // Replace with constant!
                        // This could technically be more efficient by being outside the IndexOf loop
                        // int parameters could be pasted here properly, but Unity's scripting API doesn't carry 
                        // over that information from shader parameters
                        StringBuilder sb = new StringBuilder(lines[i].Length * 2);
                        sb.Append(lines[i], 0, constantIndex);
                        switch (constant.type)
                        {
                            case PropertyType.Float:
                                sb.Append("float(" + constant.value.x.ToString(CultureInfo.InvariantCulture) + ")");
                                break;
                            case PropertyType.Vector:
                                sb.Append("float4("+constant.value.x.ToString(CultureInfo.InvariantCulture)+","
                                                   +constant.value.y.ToString(CultureInfo.InvariantCulture)+","
                                                   +constant.value.z.ToString(CultureInfo.InvariantCulture)+","
                                                   +constant.value.w.ToString(CultureInfo.InvariantCulture)+")");
                                break;
                        }
                        sb.Append(lines[i], constantIndex+constant.name.Length, lines[i].Length-constantIndex-constant.name.Length);
                        lines[i] = sb.ToString();

                        // Check for Unity branches on previous line here?
                    }
                }

                // Then remove Unity branches
                if (RemoveUnityBranches)
                    lines[i] = lines[i].Replace("UNITY_BRANCH", "").Replace("[branch]", "");

                // Replace animated properties with their generated unique names
                if (ReplaceAnimatedParameters)
                    foreach (string animPropName in animProps)
                    {
                        int nameIndex;
                        int lastIndex = 0;
                        while ((nameIndex = lines[i].IndexOf(animPropName, lastIndex, StringComparison.Ordinal)) != -1)
                        {
                            lastIndex = nameIndex+1;
                            char charLeft = ' ';
                            if (nameIndex-1 >= 0)
                                charLeft = lines[i][nameIndex-1];
                            char charRight = ' ';
                            if (nameIndex + animPropName.Length < lines[i].Length)
                                charRight = lines[i][nameIndex + animPropName.Length];
                            // Skip invalid matches (probably a subname of another symbol)
                            if (!(Array.Exists(ValidSeparators, x => x == charLeft) && Array.Exists(ValidSeparators, x => x == charRight)))
                                continue;
                            
                            StringBuilder sb = new StringBuilder(lines[i].Length * 2);
                            sb.Append(lines[i], 0, nameIndex);
                            sb.Append(animPropName + "_" + material.GetTag("AnimatedParametersSuffix", false, string.Empty));
                            sb.Append(lines[i], nameIndex+animPropName.Length, lines[i].Length-nameIndex-animPropName.Length);
                            lines[i] = sb.ToString();
                        }
                    }
            }
        }

        public static bool Unlock (Material material)
        {
            string originalShaderName = material.GetTag(OriginalShaderTag, false, string.Empty);
            if (originalShaderName.Equals(string.Empty))
            {
                Debug.LogError("[Kaj Shader Optimizer] Original shader not saved to material, could not unlock shader");
                return false;
            }
            Shader orignalShader = Shader.Find(originalShaderName);
            if (orignalShader is null)
            {
                Debug.LogError("[Kaj Shader Optimizer] Original shader " + originalShaderName + " could not be found");
                return false;
            }
            // For some reason when shaders are swapped on a material the RenderType override tag gets completely deleted and render queue set back to -1
            // So these are saved as temp values and reassigned after switching shaders
            string renderType = material.GetTag("RenderType", false, string.Empty);
            int renderQueue = material.renderQueue;
            material.shader = orignalShader;
            material.SetOverrideTag("RenderType", renderType);
            material.renderQueue = renderQueue;
            return true;
        }
    }
}