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

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Text;
using System.Globalization;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.Rendering;
using System.Linq;

#if VRC_SDK_VRCSDK3
using VRC.SDKBase;
#endif
#if VRC_SDK_VRCSDK2
using VRCSDK2;
#endif
#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
using VRC.SDKBase.Editor.BuildPipeline;
#endif


// v11

namespace Shaders.Lit
{
    
    class AutoLockOnBuild : IPreprocessBuildWithReport
    {
        public int callbackOrder { get { return 69; } }
        public void OnPreprocessBuild(BuildReport report)
        {
            ShaderOptimizer.LockAllMaterials();
        }
    }
#if BAKERY_INCLUDED
    public class ActiveBuildTargetListener : IActiveBuildTargetChanged
    {
        public int callbackOrder { get { return 69; } }

        public void OnActiveBuildTargetChanged(BuildTarget previousTarget, BuildTarget newTarget)
        {
            ShaderOptimizer.UnlockAllMaterials();
        }
    }
#endif

#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
    public class LockMaterialsOnVRCWorldUpload : IVRCSDKBuildRequestedCallback
    {
        public int callbackOrder => 69;

        bool IVRCSDKBuildRequestedCallback.OnBuildRequested(VRCSDKRequestedBuildType requestedBuildType)
        {
            ShaderOptimizer.LockAllMaterials();
            return true;
        }
    }
#endif

    public class OnShaderPreprocess : IPreprocessShaders
    {
        public int callbackOrder { get { return 69; } }

        public void OnProcessShader(Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> data)
        {
            bool shouldStrip = false;
            if (shader.name == ShaderEditor.litShaderName) shouldStrip = true; // make your shader pink if you dont lock it :>

            for (int i = data.Count - 1; i >= 0; --i)
            {
                if (shouldStrip) data.RemoveAt(i);
            }
        }
    }

    
    public enum LightMode
    {
        Always=1,
        ForwardBase=2,
        ForwardAdd=4,
        Deferred=8,
        ShadowCaster=16,
        MotionVectors=32,
        PrepassBase=64,
        PrepassFinal=128,
        Vertex=256,
        VertexLMRGBM=512,
        VertexLM=1024
    }

    // Static methods to generate new shader files with in-place constants based on a material's properties
    // and link that new shader to the material automatically
    public class ShaderOptimizer
    {
        // For some reason, 'if' statements with replaced constant (literal) conditions cause some compilation error
        // So until that is figured out, branches will be removed by default
        // Set to false if you want to keep UNITY_BRANCH and [branch]
        public static bool RemoveUnityBranches = true;

        // LOD Crossfade Dithing doesn't have multi_compile keyword correctly toggled at build time (its always included) so
        // this hard-coded material property will uncomment //#pragma multi_compile _ LOD_FADE_CROSSFADE in optimized .shader files
        public static readonly string LODCrossFadePropertyName = "_LODCrossfade";

        // IgnoreProjector and ForceNoShadowCasting don't work as override tags, so material properties by these names
        // will determine whether or not //"IgnoreProjector"="True" etc. will be uncommented in optimized .shader files
        public static readonly string IgnoreProjectorPropertyName = "_IgnoreProjector";
        public static readonly string ForceNoShadowCastingPropertyName = "_ForceNoShadowCasting";

        // Material property suffix that controls whether the property of the same name gets baked into the optimized shader
        // e.g. if _Color exists and _ColorAnimated = 1, _Color will not be baked in
        public static readonly string AnimatedPropertySuffix = "Animated";

        // Currently, Material.SetShaderPassEnabled doesn't work on "ShadowCaster" lightmodes,
        // and doesn't let "ForwardAdd" lights get turned into vertex lights if "ForwardAdd" is simply disabled
        // vs. if the pass didn't exist at all in the shader.
        // The Optimizer will take a mask property by this name and attempt to correct these issues
        // by hard-removing the shadowcaster and fwdadd passes from the shader being optimized.
        public static readonly string DisabledLightModesPropertyName = "_LightModes";

        // Property that determines whether or not to evaluate KSOInlineSamplerState comments.
        // Inline samplers can be used to get a wider variety of wrap/filter combinations at the cost
        // of only having 1x anisotropic filtering on all textures
        public static readonly string UseInlineSamplerStatesPropertyName = "_InlineSamplerStates";
        private static bool UseInlineSamplerStates = true;

        // Material properties are put into each CGPROGRAM as preprocessor defines when the optimizer is run.
        // This is mainly targeted at culling interpolators and lines that rely on those interpolators.
        // (The compiler is not smart enough to cull VS output that isn't used anywhere in the PS)
        // Additionally, simply enabling the optimizer can define a keyword, whose name is stored here.
        // This keyword is added to the beginning of all passes, right after CGPROGRAM
        public static readonly string OptimizerEnabledKeyword = "OPTIMIZER_ENABLED";

        // Mega shaders are expected to have geometry and tessellation shaders enabled by default,
        // but with the ability to be disabled by convention property names when the optimizer is run.
        // Additionally, they can be removed per-lightmode by the given property name plus 
        // the lightmode name as a suffix (e.g. group_toggle_GeometryShadowCaster)
        // Geometry and Tessellation shaders are REMOVED by default, but if the main gorups
        // are enabled certain pass types are assumed to be ENABLED
        public static readonly string GeometryShaderEnabledPropertyName = "group_toggle_Geometry";
        public static readonly string TessellationEnabledPropertyName = "group_toggle_Tessellation";
        private static bool UseGeometry = false;
        private static bool UseGeometryForwardBase = true;
        private static bool UseGeometryForwardAdd = true;
        private static bool UseGeometryShadowCaster = true;
        private static bool UseGeometryMeta = true;
        private static bool UseTessellation = false;
        private static bool UseTessellationForwardBase = true;
        private static bool UseTessellationForwardAdd = true;
        private static bool UseTessellationShadowCaster = true;
        private static bool UseTessellationMeta = false;

        // Tessellation can be slightly optimized with a constant max tessellation factor attribute
        // on the hull shader.  A non-animated property by this name will replace the argument of said
        // attribute if it exists.
        public static readonly string TessellationMaxFactorPropertyName = "_TessellationFactorMax";

        // Material property animations in Unity (using the Animator component) affect the properties
        // of all materials on the attatched mesh, rather than on individual mesh material slots.  The
        // optimizer provides an option to replace animated material properties (ones marked with the
        // animated property suffix) with a random unique name to avoid this problem entirely.
        // A parameter of this name will determine whether or not this is done when the optimizer is run.
        public static readonly string ReplaceAnimatedParametersPropertyName = "_ReplaceAnimatedParameters";
        private static bool ReplaceAnimatedParameters = false;

        private static string CurrentLightmode = "";

        public static void LockMaterial(Material mat, bool applyLater, Material sharedMaterial)
        {

            mat.SetFloat("_ShaderOptimizerEnabled", 1);
            MaterialProperty[] props = MaterialEditor.GetMaterialProperties(new UnityEngine.Object[] { mat });
            if (!ShaderOptimizer.Lock(mat, props, applyLater, sharedMaterial)) // Error locking shader, revert property
                mat.SetFloat("_ShaderOptimizerEnabled", 0);
        }

        [MenuItem("Tools/Lit/Unlock all materials")]
        public static void UnlockAllMaterials()
        {
            #if BAKERY_INCLUDED
            ftLightmapsStorage storage = ftRenderLightmap.FindRenderSettingsStorage();
            if(storage.renderSettingsRenderDirMode == 3 || storage.renderSettingsRenderDirMode == 4) RevertHandleBakeryPropertyBlocks();
            #endif
            List<Material> mats = new List<Material>();
            var renderers = UnityEngine.Object.FindObjectsOfType<Renderer>();

            if(renderers != null) foreach (var rend in renderers)
            {
                if(rend != null) foreach (var mat in rend.sharedMaterials)
                {
                    if(mat != null)
                    {
                        if(mat.shader.name.StartsWith("Hidden/" + ShaderEditor.litShaderName) || mat.GetTag("OriginalShader", false) == ShaderEditor.litShaderName || mat.GetTag("OriginalShader", false).StartsWith("Hidden/" + ShaderEditor.litShaderName))
                        {
                            if(!mats.Contains(mat)) mats.Add(mat);
                        }
                        else if (mat.shader.name == ShaderEditor.litShaderName)
                        {
                            mat.SetFloat("_ShaderOptimizerEnabled", 0);
                        }
                    }
                }
            }

            foreach (Material m in mats)
            {
                ShaderOptimizer.Unlock(m);
                m.SetFloat("_ShaderOptimizerEnabled", 0);
            }
        }
        
        [MenuItem("Tools/Lit/Lock all materials")]
        public static void LockAllMaterials()
        {
            
            #if BAKERY_INCLUDED && !UNITY_ANDROID
            ftLightmapsStorage storage = ftRenderLightmap.FindRenderSettingsStorage();
            if(storage.renderSettingsRenderDirMode == 3 || storage.renderSettingsRenderDirMode == 4) HandleBakeryPropertyBlocks();
            #endif
            List<Material> mats = GetAllMaterials(ShaderEditor.litShaderName);
            if(mats.Count > 0)
            {
                AssetDatabase.StartAssetEditing();
                List<Material> lockedMats = GetAllLockedMaterials();
                List<Material> allMaterials = new List<Material>();
                allMaterials.AddRange(mats);
                allMaterials.AddRange(lockedMats);
                float progress = mats.Count;

                List<String> shaderPropertyNames = new List<String>();

                string originalShaderPath = AssetDatabase.GetAssetPath(mats[0].shader);

                Shader shader = (Shader)AssetDatabase.LoadAssetAtPath( originalShaderPath, typeof( Shader ) );

                int propCount = ShaderUtil.GetPropertyCount(shader);

                for(int l=0; l<propCount; l++)
                {
                    string st = ShaderUtil.GetPropertyName (shader, l);
                    shaderPropertyNames.Add(st);

                }


                


                
                for (int i=0; i<progress; i++)
                {
                    EditorUtility.DisplayCancelableProgressBar("Generating Shaders", mats[i].name, i/progress);
                    MaterialProperty[] propsI = MaterialEditor.GetMaterialProperties(new UnityEngine.Object[] { mats[i] });
                    List<MaterialProperty> propsIclean = new List<MaterialProperty>();

                    Material sharedMaterial = null;
                    

                    foreach(MaterialProperty p in propsI)
                    {
                        if(shaderPropertyNames.Contains(p.name)) propsIclean.Add(p);
                    }


                    for (int j=0; j<allMaterials.Count; j++)
                    {
                        bool canShare = true;
                        if(mats[i] == allMaterials[j]) canShare = false;
                        else
                        {
                            MaterialProperty[] propsJ = MaterialEditor.GetMaterialProperties(new UnityEngine.Object[] { allMaterials[j] });
                            List<MaterialProperty> propsJclean = new List<MaterialProperty>();

                            foreach(MaterialProperty p in propsJ)
                            {
                                if(shaderPropertyNames.Contains(p.name)) propsJclean.Add(p);  
                            }

                    

                            for (int k=0; k<propCount; k++)
                            {
                                switch(propsIclean[k].type)
                                {
                                    case MaterialProperty.PropType.Float:
                                        if(propsIclean[k].name == "_ShaderOptimizerEnabled") break;
                                        if(propsIclean[k].name == "_BlendOp") break;
                                        if(propsIclean[k].name == "_BlendOpAlpha") break;
                                        if(propsIclean[k].name == "_SrcBlend") break;
                                        if(propsIclean[k].name == "_DstBlend") break;
                                        if(propsIclean[k].name == "_ZWrite") break;
                                        if(propsIclean[k].name == "_ZTest") break;
                                        if(propsIclean[k].name == "_Cull") break;
                                        if(propsIclean[k].floatValue != propsJclean[k].floatValue) canShare = false;
                                        break;
                                    case MaterialProperty.PropType.Texture:
                                        if(propsIclean[k].name == "_MainTex") break;
                                        if(propsIclean[k].textureValue != null || propsJclean[k].textureValue != null)
                                        {
                                            if(propsIclean[k].textureScaleAndOffset != propsJclean[k].textureScaleAndOffset) canShare = false;
                                        }
                                        if(propsIclean[k].textureValue == null && propsJclean[k].textureValue == null) {}
                                        else if(propsIclean[k].textureValue != null && propsJclean[k].textureValue != null) {}
                                        else canShare = false;
                                        break;
                                    case MaterialProperty.PropType.Color:
                                        if(propsIclean[k].name == "_Color") break;
                                        if(propsIclean[k].colorValue != propsJclean[k].colorValue) canShare = false;
                                        break;
                                    case MaterialProperty.PropType.Range:
                                        if(propsIclean[k].name == "_Glossiness") break;
                                        if(propsIclean[k].name == "_Metallic") break;
                                        if(propsIclean[k].name == "_Reflectance") break;
                                        if(propsIclean[k].name == "_BumpScale") break;
                                        if(propsIclean[k].floatValue != propsJclean[k].floatValue) canShare = false;
                                        break;
                                    case MaterialProperty.PropType.Vector:
                                        if(propsIclean[k].vectorValue != propsJclean[k].vectorValue) canShare = false;
                                        break;
                                }
                                

                            }


                            if(canShare) sharedMaterial = allMaterials[j];
                        }
                        
                        

                    }

                    if(sharedMaterial != null)
                    {
                        for(int m=0; m<allMaterials.Count; m++)
                            {
                                if(mats[i] == allMaterials[m])
                                {
                                    allMaterials[m] = sharedMaterial;
                                }
                            }
                        //Debug.Log($"Share {mats[i]} with {sharedMaterial}");
                    }

                    //else Debug.Log($"Share {mats[i]} with None");


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
        }

        public static List<Material> GetAllMaterials(string shaderName)
        {
            List<Material> materials = new List<Material>();
            var renderers = UnityEngine.Object.FindObjectsOfType<Renderer>();

            if(renderers != null) foreach (var rend in renderers)
            {
                if(rend != null) foreach (var mat in rend.sharedMaterials)
                {
                    if(mat != null) if(mat.shader.name == shaderName)
                    {
                        if(!materials.Contains(mat)) materials.Add(mat);
                    }
                }
            }
            return materials;
        }

        public static List<Material> GetAllLockedMaterials()
        {
            List<Material> materials = new List<Material>();
            var renderers = UnityEngine.Object.FindObjectsOfType<Renderer>();

            if(renderers != null) foreach (var rend in renderers)
            {
                if(rend != null) foreach (var mat in rend.sharedMaterials)
                {
                    if(mat != null) if(mat.shader.name.StartsWith("Hidden/" + ShaderEditor.litShaderName))
                    {
                        if(!materials.Contains(mat)) materials.Add(mat);
                    }
                }
            }
            return materials;
        }

        /**
        * MIT License
        * 
        * Copyright (c) 2019 Merlin
        * 
        * Permission is hereby granted, free of charge, to any person obtaining a copy
        * of this software and associated documentation files (the "Software"), to deal
        * in the Software without restriction, including without limitation the rights
        * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        * copies of the Software, and to permit persons to whom the Software is
        * furnished to do so, subject to the following conditions:
        * 
        * The above copyright notice and this permission notice shall be included in all
        * copies or substantial portions of the Software.
        * 
        * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        * SOFTWARE.
        */

        [MenuItem("Tools/Lit/HandleBakeryPropertyBlocks")]
        public static void HandleBakeryPropertyBlocks()
        {
            const string newMaterialPath = "Assets/GeneratedMaterials/";
            if (!Directory.Exists(newMaterialPath)) Directory.CreateDirectory(newMaterialPath);

            MeshRenderer[] renderers = UnityEngine.Object.FindObjectsOfType<MeshRenderer>();
            Dictionary<string, Material> generatedMaterialList = new Dictionary<string, Material>();

            foreach(MeshRenderer mr in renderers)
            {
                MaterialPropertyBlock propertyBlock = new MaterialPropertyBlock();
                mr.GetPropertyBlock(propertyBlock);
                Texture RNM0 = propertyBlock.GetTexture("_RNM0");
                Texture RNM1 = propertyBlock.GetTexture("_RNM1");
                Texture RNM2 = propertyBlock.GetTexture("_RNM2");
                int propertyLightmapMode = (int)propertyBlock.GetFloat("bakeryLightmapMode");

                if(RNM0 && RNM1 && RNM2 && propertyLightmapMode != 0)
                {
                    Material[] newSharedMaterials = new Material[mr.sharedMaterials.Length];

                    for (int j = 0; j < mr.sharedMaterials.Length; j++)
                    {
                        Material material = mr.sharedMaterials[j];
                        if  (material != null && 
                            (material.shader.name.Contains(ShaderEditor.litShaderName) || material.shader.name.StartsWith("Hidden/" + ShaderEditor.litShaderName)) &&
                            material.GetTag("OriginalMaterialPath", false) == "")
                        {
                            string materialPath = AssetDatabase.GetAssetPath(material);
                            string textureName = AssetDatabase.GetAssetPath(RNM0) + "_" + AssetDatabase.GetAssetPath(RNM1) + "_" + AssetDatabase.GetAssetPath(RNM2);
                            string matTexHash = ComputeMD5(materialPath + textureName);


                            Material newMaterial = null;

                            generatedMaterialList.TryGetValue(matTexHash, out newMaterial);
                            if (newMaterial == null)
                            {
                                newMaterial = new Material(material);
                                newMaterial.name = matTexHash;
                                newMaterial.SetTexture("_RNM0", RNM0);
                                newMaterial.SetTexture("_RNM1", RNM1);
                                newMaterial.SetTexture("_RNM2", RNM2);
                                newMaterial.SetInt("bakeryLightmapMode", propertyLightmapMode);
                                newMaterial.SetOverrideTag("OriginalMaterialPath", AssetDatabase.AssetPathToGUID(materialPath));
                                generatedMaterialList.Add(matTexHash, newMaterial);

                                
                                try
                                {
                                    AssetDatabase.CreateAsset(newMaterial, newMaterialPath + matTexHash + ".mat");
                                }
                                catch(Exception e)
                                {
                                    Debug.LogError($"Unable to create new material {newMaterial.name} for {mr} {e}");
                                }

                                //Debug.Log($"Created new material for {mr} named {newMaterial.name}");

                            }

                            newSharedMaterials[j] = newMaterial;

                        }
                        else if (material != null)
                        {
                            newSharedMaterials[j] = material;
                        }
                    }

                    mr.sharedMaterials = newSharedMaterials;
                }
            }

            AssetDatabase.Refresh();
        }
        
        [MenuItem("Tools/Lit/RevertBakeryPropertyBlocks")]
        public static void RevertHandleBakeryPropertyBlocks()
        {
            var renderers = UnityEngine.Object.FindObjectsOfType<MeshRenderer>();

            if(renderers != null) foreach (var rend in renderers)
            {
                Material[] oldMaterials = new Material[rend.sharedMaterials.Length];

                if(rend != null)
                {
                    for (int i = 0; i < rend.sharedMaterials.Length; i++)
                    {

                        if( rend.sharedMaterials[i] != null)
                        {
                            string originalMatPath = rend.sharedMaterials[i].GetTag("OriginalMaterialPath", false, "");
                            if(originalMatPath != "")
                            {
                                try
                                {
                                    Material oldMat = (Material)AssetDatabase.LoadAssetAtPath(AssetDatabase.GUIDToAssetPath(originalMatPath), typeof(Material));
                                    oldMaterials[i] = oldMat;
                                }
                                catch
                                {
                                    Debug.LogError($"Unable to find original material  at {originalMatPath} for {rend.sharedMaterials[i]} for {rend}");
                                    oldMaterials[i] = rend.sharedMaterials[i];
                                }
                            }
                            else
                            {
                                oldMaterials[i] = rend.sharedMaterials[i];
                            }
                        }
                    }
                    rend.sharedMaterials = oldMaterials;
                }
            }
        }

        // https://forum.unity.com/threads/hash-function-for-game.452779/
        private static string ComputeMD5(string str)
        {
            System.Text.ASCIIEncoding encoding = new System.Text.ASCIIEncoding();
            byte[] bytes = encoding.GetBytes(str);
            var sha = new System.Security.Cryptography.MD5CryptoServiceProvider();
            return BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-", "").ToLower();
        }


        // In-order list of inline sampler state names that will be replaced by InlineSamplerState() lines
        public static readonly string[] InlineSamplerStateNames = new string[]
        {
            "_linear_repeat",
            "_linear_clamp",
            "_linear_mirror",
            "_linear_mirroronce",
            "_point_repeat",
            "_point_clamp",
            "_point_mirror",
            "_point_mirroronce",
            "_trilinear_repeat",
            "_trilinear_clamp",
            "_trilinear_mirror",
            "_trilinear_mirroronce"
        };

        // Would be better to dynamically parse the "C:\Program Files\UnityXXXX\Editor\Data\CGIncludes\" folder
        // to get version specific includes but eh
        public static readonly string[] DefaultUnityShaderIncludes = new string[]
        {
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

        public static readonly char[] ValidSeparators = new char[] {' ','\t','\r','\n',';',',','.','(',')','[',']','{','}','>','<','=','!','&','|','^','+','-','*','/','#','?' };

        public static readonly string[] ValidPropertyDataTypes = new string[]
        {
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

        public class PropertyData
        {
            public PropertyType type;
            public string name;
            public Vector4 value;
        }

        public class Macro
        {
            public string name;
            public string[] args;
            public string contents;
        }

        public class ParsedShaderFile
        {
            public string filePath;
            public string[] lines;
        }

        public class TextureProperty
        {
            public string name;
            public Texture texture;
            public int uv;
            public Vector2 scale;
            public Vector2 offset;
        }

        public class GrabPassReplacement
        {
            public string originalName;
            public string newName;
        }

        public class ShaderOptimizerLockButtonDrawer : MaterialPropertyDrawer
        {
            public override void OnGUI(Rect position, MaterialProperty shaderOptimizer, string label, MaterialEditor materialEditor)
            {
                // Theoretically this shouldn't ever happen since locked in materials have different shaders.
                // But in a case where the material property says its locked in but the material really isn't, this
                // will display and allow users to fix the property/lock in
                if (shaderOptimizer.hasMixedValue)
                {
                    EditorGUI.BeginChangeCheck();
                    GUILayout.Button("Lock in Optimized Shaders (" + materialEditor.targets.Length + " materials)");
                    if (EditorGUI.EndChangeCheck())
                        foreach (Material m in materialEditor.targets)
                        {
                            m.SetFloat(shaderOptimizer.name, 1);
                            MaterialProperty[] props = MaterialEditor.GetMaterialProperties(new UnityEngine.Object[] { m });
                            if (!ShaderOptimizer.Lock(m, props)) // Error locking shader, revert property
                                m.SetFloat(shaderOptimizer.name, 0);
                        }
                }
                else
                {
                    EditorGUI.BeginChangeCheck();
                    if (shaderOptimizer.floatValue == 0)
                    {
                        if (materialEditor.targets.Length == 1)
                            GUILayout.Button("Lock In Optimized Shader");
                        else GUILayout.Button("Lock in Optimized Shaders (" + materialEditor.targets.Length + " materials)");
                    }
                    else GUILayout.Button("Unlock Shader");
                    if (EditorGUI.EndChangeCheck())
                    {
                        shaderOptimizer.floatValue = shaderOptimizer.floatValue == 1 ? 0 : 1;
                        if (shaderOptimizer.floatValue == 1)
                        {
                            foreach (Material m in materialEditor.targets)
                            {
                                MaterialProperty[] props = MaterialEditor.GetMaterialProperties(new UnityEngine.Object[] { m });
                                if (!ShaderOptimizer.Lock(m, props))
                                    m.SetFloat(shaderOptimizer.name, 0);
                            }
                        }
                        else
                        {
                            foreach (Material m in materialEditor.targets)
                                if (!ShaderOptimizer.Unlock(m))
                                    m.SetFloat(shaderOptimizer.name, 1);
                        }
                    }
                }
            }

            public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
            {
                return -2;
            }
        }

        public static bool Lock(Material material, MaterialProperty[] props)
        {
            Lock(material, props, false, null);
            return true;
        }

        public static bool Lock(Material material, MaterialProperty[] props, bool applyShaderLater, Material sharedMaterial)
        {
 
            Shader shader = material.shader;
            string shaderFilePath = AssetDatabase.GetAssetPath(shader);
            string smallguid = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(material));
            string newShaderName = "Hidden/" + shader.name + "/" + smallguid;
            string newShaderDirectory = "Assets/OptimizedShaders/" + smallguid + "/";
            ApplyLater applyLater = new ApplyLater();
            
            
            if(sharedMaterial != null)
            {
                applyLater.material = material;
                applyLater.shader = sharedMaterial.shader;
                applyLater.smallguid = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(sharedMaterial));
                applyLater.newShaderName = "Hidden/" + shader.name + "/" + applyLater.smallguid;
                applyStructsLater.Add(material, applyLater);
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
                if (keyword == "") continue; // idk why but null keywords exist if _ keyword is used and not removed by the editor at some point
                definesSB.Append("#define ");
                definesSB.Append(keyword);
                definesSB.Append(Environment.NewLine);
            }

            List<PropertyData> constantProps = new List<PropertyData>();
            List<string> animatedProps = new List<string>();
            foreach (MaterialProperty prop in props)
            {
                if (prop == null) continue;

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
                 (material.GetTag(prop.name.ToString() + AnimatedPropertySuffix, false) == "" ? false : true) ||
                 (prop.name == "_Glossiness") ||
                 (prop.name == "_Metallic") ||
                 (prop.name == "_BumpScale") ||
                 #if UNITY_ANDROID
                 (prop.name == "bakeryLightmapMode") ||
                 #endif
                 (prop.name == "_Reflectance") ||
                 (prop.name == "_Color")
                 )
                    continue;
                else if (prop.name == UseInlineSamplerStatesPropertyName)
                {
                    UseInlineSamplerStates = (prop.floatValue == 1);
                    continue;
                }
                else if (prop.name.StartsWith(GeometryShaderEnabledPropertyName))
                {
                    if (prop.name == GeometryShaderEnabledPropertyName)
                        UseGeometry = (prop.floatValue == 1);
                    else if (prop.name == GeometryShaderEnabledPropertyName + "ForwardBase")
                        UseGeometryForwardBase = (prop.floatValue == 1);
                    else if (prop.name == GeometryShaderEnabledPropertyName + "ForwardAdd")
                        UseGeometryForwardAdd = (prop.floatValue == 1);
                    else if (prop.name == GeometryShaderEnabledPropertyName + "ShadowCaster")
                        UseGeometryShadowCaster = (prop.floatValue == 1);
                    else if (prop.name == GeometryShaderEnabledPropertyName + "Meta")
                        UseGeometryMeta = (prop.floatValue == 1);
                }
                else if (prop.name.StartsWith(TessellationEnabledPropertyName))
                {
                    if (prop.name == TessellationEnabledPropertyName)
                        UseTessellation = (prop.floatValue == 1);
                    else if (prop.name == TessellationEnabledPropertyName + "ForwardBase")
                        UseTessellationForwardBase = (prop.floatValue == 1);
                    else if (prop.name == TessellationEnabledPropertyName + "ForwardAdd")
                        UseTessellationForwardAdd = (prop.floatValue == 1);
                    else if (prop.name == TessellationEnabledPropertyName + "ShadowCaster")
                        UseTessellationShadowCaster = (prop.floatValue == 1);
                    else if (prop.name == TessellationEnabledPropertyName + "Meta")
                        UseTessellationMeta = (prop.floatValue == 1);
                }
                else if (prop.name == ReplaceAnimatedParametersPropertyName)
                {
                    ReplaceAnimatedParameters = (prop.floatValue == 1);
                    if (ReplaceAnimatedParameters)
                    {
                        // Add a tag to the material so animation clip referenced parameters 
                        // will stay consistent across material locking/unlocking
                        string animatedParameterSuffix = material.GetTag("AnimatedParametersSuffix", false, "");
                        if (animatedParameterSuffix == "")
                            material.SetOverrideTag("AnimatedParametersSuffix", Guid.NewGuid().ToString().Split('-')[0]);
                    }
                }


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

            // Get list of lightmode passes to delete
            List<string> disabledLightModes = new List<string>();
            var disabledLightModesProperty = Array.Find(props, x => x.name == DisabledLightModesPropertyName);
            if (disabledLightModesProperty != null)
            {
                int lightModesMask = (int)disabledLightModesProperty.floatValue;
                if ((lightModesMask & (int)LightMode.ForwardAdd) != 0)
                    disabledLightModes.Add("ForwardAdd");
                if ((lightModesMask & (int)LightMode.ShadowCaster) != 0)
                    disabledLightModes.Add("ShadowCaster");
            }
                
            // Parse shader and cginc files, also gets preprocessor macros
            List<ParsedShaderFile> shaderFiles = new List<ParsedShaderFile>();
            List<Macro> macros = new List<Macro>();
            if (!ParseShaderFilesRecursive(shaderFiles, newShaderDirectory, shaderFilePath, macros, material))
                return false;
            

            List<GrabPassReplacement> grabPassVariables = new List<GrabPassReplacement>();
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
                        else if (trimmedLine.StartsWith("//#pragma multi_compile _ LOD_FADE_CROSSFADE"))
                        {
                            MaterialProperty crossfadeProp = Array.Find(props, x => x.name == LODCrossFadePropertyName);
                            if (crossfadeProp != null && crossfadeProp.floatValue == 1)
                                psf.lines[i] = psf.lines[i].Replace("//#pragma", "#pragma");
                        }
                        else if (trimmedLine.StartsWith("//\"IgnoreProjector\"=\"True\""))
                        {
                            MaterialProperty projProp = Array.Find(props, x => x.name == IgnoreProjectorPropertyName);
                            if (projProp != null && projProp.floatValue == 1)
                                psf.lines[i] = psf.lines[i].Replace("//\"IgnoreProjector", "\"IgnoreProjector");
                        }
                        else if (trimmedLine.StartsWith("//\"ForceNoShadowCasting\"=\"True\""))
                        {
                            MaterialProperty forceNoShadowsProp = Array.Find(props, x => x.name == ForceNoShadowCastingPropertyName);
                            if (forceNoShadowsProp != null && forceNoShadowsProp.floatValue == 1)
                                psf.lines[i] = psf.lines[i].Replace("//\"ForceNoShadowCasting", "\"ForceNoShadowCasting");
                        }
                        else if (trimmedLine.StartsWith("GrabPass {"))
                        {
                            GrabPassReplacement gpr = new GrabPassReplacement();
                            string[] splitLine = trimmedLine.Split('\"');
                            if (splitLine.Length == 1)
                                gpr.originalName = "_GrabTexture";
                            else
                                gpr.originalName = splitLine[1];
                            gpr.newName = material.GetTag("GrabPass" + grabPassVariables.Count, false, "_GrabTexture");
                            psf.lines[i] = "GrabPass { \"" + gpr.newName + "\" }";
                            grabPassVariables.Add(gpr);
                        }
                        else if (trimmedLine.StartsWith("CGINCLUDE"))
                        {
                            for (int j=i+1; j<psf.lines.Length;j++)
                                if (psf.lines[j].TrimStart().StartsWith("ENDCG"))
                                {
                                    ReplaceShaderValues(material, psf.lines, i+1, j, props, constantProps, animatedProps, macros, grabPassVariables);
                                    break;
                                }
                        }
                        else if (trimmedLine.StartsWith("CGPROGRAM"))
                        {
                            psf.lines[i] += optimizerDefines;
                            for (int j=i+1; j<psf.lines.Length;j++)
                                if (psf.lines[j].TrimStart().StartsWith("ENDCG"))
                                {
                                    ReplaceShaderValues(material, psf.lines, i+1, j, props, constantProps, animatedProps, macros, grabPassVariables);
                                    break;
                                }
                        }
                        // Lightmode based pass removal, requires strict formatting
                        else if (trimmedLine.StartsWith("Tags"))
                        {
                            string lineFullyTrimmed = trimmedLine.Replace(" ", "").Replace("\t", "");
                            // expects lightmode tag to be on the same line like: Tags { "LightMode" = "ForwardAdd" }
                            if (lineFullyTrimmed.Contains("\"LightMode\"=\""))
                            {
                                string lightModeName = lineFullyTrimmed.Split('\"')[3];
                                // Store current lightmode name in a static, useful for per-pass geometry and tessellation removal
                                CurrentLightmode = lightModeName;
                                if (disabledLightModes.Contains(lightModeName))
                                {
                                    // Loop up from psf.lines[i] until standalone "Pass" line is found, delete it
                                    int j=i-1;
                                    for (;j>=0;j--)
                                        if (psf.lines[j].Replace(" ", "").Replace("\t", "") == "Pass")
                                            break;
                                    // then delete each line until a standalone ENDCG line is found
                                    for (;j<psf.lines.Length;j++)
                                    {
                                        if (psf.lines[j].Replace(" ", "").Replace("\t", "") == "ENDCG")
                                            break;
                                        psf.lines[j] = "";
                                    }
                                    // then delete each line until a standalone '}' line is found
                                    for (;j<psf.lines.Length;j++)
                                    {
                                        string temp = psf.lines[j];
                                        psf.lines[j] = "";
                                        if (temp.Replace(" ", "").Replace("\t", "") == "}")
                                            break;
                                    }
                                }
                            }
                        }
                        else if (ReplaceAnimatedParameters)
                        {
                            // Check to see if line contains an animated property name with valid left/right characters
                            // then replace the parameter name with prefixtag + parameter name
                            string animatedPropName = animatedProps.Find(x => trimmedLine.Contains(x));
                            if (animatedPropName != null)
                            {
                                int parameterIndex = trimmedLine.IndexOf(animatedPropName);
                                char charLeft = trimmedLine[parameterIndex-1];
                                char charRight = trimmedLine[parameterIndex + animatedPropName.Length];
                                if (Array.Exists(ValidSeparators, x => x == charLeft) && Array.Exists(ValidSeparators, x => x == charRight))
                                    psf.lines[i] = psf.lines[i].Replace(animatedPropName, animatedPropName + material.GetTag("AnimatedParametersSuffix", false, ""));
                            }
                        }
                    }
                }
                else // CGINC file
                    ReplaceShaderValues(material, psf.lines, 0, psf.lines.Length, props, constantProps, animatedProps, macros, grabPassVariables);

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
                    Debug.LogError("[Kaj Shader Optimizer] Processed shader file " + newShaderDirectory + newDirectory + " could not be written.  " + e.ToString());
                    return false;
                }
            }
            

            applyLater.material = material;
            applyLater.shader = shader;
            applyLater.smallguid = smallguid;
            applyLater.newShaderName = newShaderName;

            if (applyShaderLater)
            {
                applyStructsLater.Add(material, applyLater);
                return true;
            }

            AssetDatabase.Refresh();

            // Loop through animated properties and set new properties to current property values
            /*
            if (ReplaceAnimatedParameters)
                foreach (string animatedPropName in animatedProps)
                {
                    MaterialProperty mpa = MaterialEditor.GetMaterialProperty(new UnityEngine.Object[] { material }, animatedPropName + material.GetTag("AnimatedParametersSuffix", false, ""));
                    MaterialProperty propOriginal = Array.Find(props, x => x.name == animatedPropName);
                    switch (mpa.type)
                    {
                        case MaterialProperty.PropType.Color:
                            mpa.colorValue = propOriginal.colorValue;
                            break;
                        case MaterialProperty.PropType.Vector:
                            mpa.vectorValue = propOriginal.vectorValue;
                            break;
                        case MaterialProperty.PropType.Float:
                        case MaterialProperty.PropType.Range:
                            mpa.floatValue = propOriginal.floatValue;
                            break;
                        case MaterialProperty.PropType.Texture:
                            mpa.textureValue = propOriginal.textureValue;
                            break;
                    }
                }
                */

            

                return ReplaceShader(applyLater);
        }

        private static Dictionary<Material, ApplyLater> applyStructsLater = new Dictionary<Material, ApplyLater>();

        private struct ApplyLater
        {
            public Material material;
            public Shader shader;
            public string smallguid;
            public string newShaderName;
        }
        
        private static bool LockApplyShader(Material material)
        {
            if (applyStructsLater.ContainsKey(material) == false) return false;
            ApplyLater applyStruct = applyStructsLater[material];
            applyStructsLater.Remove(material);
            return ReplaceShader(applyStruct);
        }


        private static bool ReplaceShader(ApplyLater applyLater)
        {

            // Write original shader to override tag
            applyLater.material.SetOverrideTag("OriginalShader", applyLater.shader.name);
            // Write the new shader folder name in an override tag so it will be deleted 
            applyLater.material.SetOverrideTag("OptimizedShaderFolder", applyLater.smallguid);

            

            // For some reason when shaders are swapped on a material the RenderType override tag gets completely deleted and render queue set back to -1
            // So these are saved as temp values and reassigned after switching shaders
            string renderType = applyLater.material.GetTag("RenderType", false, "");
            int renderQueue = applyLater.material.renderQueue;

            // Actually switch the shader
            Shader newShader = Shader.Find(applyLater.newShaderName);
            
            if (newShader == null)
            {
               // LockMaterial(applyLater.material, false, null);
                Debug.LogError("[Kaj Shader Optimizer] Generated shader " + applyLater.newShaderName + " for " + applyLater.material +" could not be found ");
                return false;
            }
            applyLater.material.shader = newShader;
            applyLater.material.SetOverrideTag("RenderType", renderType);
            applyLater.material.renderQueue = renderQueue;

            // Remove ALL keywords
            foreach (string keyword in applyLater.material.shaderKeywords)
            applyLater.material.DisableKeyword(keyword);

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
            string fileContents = null;
            try
            {
                StreamReader sr = new StreamReader(filePath);
                fileContents = sr.ReadToEnd();
                sr.Close();
            }
            catch (FileNotFoundException e)
            {
                Debug.LogError("[Kaj Shader Optimizer] Shader file " + filePath + " not found.  " + e.ToString());
                return false;
            }
            catch (IOException e)
            {
                Debug.LogError("[Kaj Shader Optimizer] Error reading shader file.  " + e.ToString());
                return false;
            }

            // Parse file line by line
            List<String> macrosList = new List<string>();
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
                        if(!materialProperties.Any(x => Convert.ToBoolean(mat.GetFloat(x))))
                        {
                            i++;
                            fileLines[i] = fileLines[i].Insert(0, "//");
                            continue;
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
                // Specifically requires no whitespace between // and KSOEvaluateMacro
                else if (lineParsed == "//KSOEvaluateMacro")
                {
                    string macro = "";
                    string lineTrimmed = null;
                    do
                    {
                        i++;
                        lineTrimmed = fileLines[i].TrimEnd();
                        if (lineTrimmed.EndsWith("\\"))
                            macro += lineTrimmed.TrimEnd('\\') + Environment.NewLine; // keep new lines in macro to make output more readable
                        else macro += lineTrimmed;
                    } 
                    while (lineTrimmed.EndsWith("\\"));
                    macrosList.Add(macro);
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
        private static void ReplaceShaderValues(Material material, string[] lines, int startLine, int endLine, 
        MaterialProperty[] props, List<PropertyData> constants, List<string> animProps, List<Macro> macros, List<GrabPassReplacement> grabPassVariables)
        {
            List <TextureProperty> uniqueSampledTextures = new List<TextureProperty>();

            for (int i=startLine;i<endLine;i++)
            {
                string lineTrimmed = lines[i].TrimStart();
                if (lineTrimmed.StartsWith("#pragma geometry"))
                {
                    if (!UseGeometry)
                        lines[i] = "//" + lines[i];
                    else
                    {
                        switch (CurrentLightmode)
                        {
                            case "ForwardBase":
                                if (!UseGeometryForwardBase)
                                    lines[i] = "//" + lines[i];
                                break;
                            case "ForwardAdd":
                                if (!UseGeometryForwardAdd)
                                    lines[i] = "//" + lines[i];
                                break;
                            case "ShadowCaster":
                                if (!UseGeometryShadowCaster)
                                    lines[i] = "//" + lines[i];
                                break;
                            case "Meta":
                                if (!UseGeometryMeta)
                                    lines[i] = "//" + lines[i];
                                break;
                        }
                    }
                }
                else if (lineTrimmed.StartsWith("#pragma hull") || lineTrimmed.StartsWith("#pragma domain"))
                {
                    if (!UseTessellation)
                        lines[i] = "//" + lines[i];
                    else
                    {
                        switch (CurrentLightmode)
                        {
                            case "ForwardBase":
                                if (!UseTessellationForwardBase)
                                    lines[i] = "//" + lines[i];
                                break;
                            case "ForwardAdd":
                                if (!UseTessellationForwardAdd)
                                    lines[i] = "//" + lines[i];
                                break;
                            case "ShadowCaster":
                                if (!UseTessellationShadowCaster)
                                    lines[i] = "//" + lines[i];
                                break;
                            case "Meta":
                                if (!UseTessellationMeta)
                                    lines[i] = "//" + lines[i];
                                break;
                        }
                    }
                }
                // Remove all shader_feature directives
                else if (lineTrimmed.StartsWith("#pragma shader_feature") || lineTrimmed.StartsWith("#pragma shader_feature_local"))
                    lines[i] = "//" + lines[i];
                // Replace inline smapler states
                else if (UseInlineSamplerStates && lineTrimmed.StartsWith("//KSOInlineSamplerState"))
                {
                    //string lineParsed = lineTrimmed.Replace(" ", "").Replace("\t", "");
                    string lineParsed = Regex.Replace(lineTrimmed, "[ \t]", "");
                    // Remove all whitespace
                    int firstParenthesis = lineParsed.IndexOf('(');
                    int lastParenthesis = lineParsed.IndexOf(')');
                    string argsString = lineParsed.Substring(firstParenthesis+1, lastParenthesis - firstParenthesis-1);
                    string[] args = argsString.Split(',');
                    MaterialProperty texProp = Array.Find(props, x => x.name == args[1]);
                    if (texProp != null)
                    {
                        Texture t = texProp.textureValue;
                        int inlineSamplerIndex = 0;
                        if (t != null)
                        {
                            switch (t.filterMode)
                            {
                                case FilterMode.Bilinear:
                                    break;
                                case FilterMode.Point:
                                    inlineSamplerIndex += 1 * 4;
                                    break;
                                case FilterMode.Trilinear:
                                    inlineSamplerIndex += 2 * 4;
                                    break;
                            }
                            switch (t.wrapMode)
                            {
                                case TextureWrapMode.Repeat:
                                    break;
                                case TextureWrapMode.Clamp:
                                    inlineSamplerIndex += 1;
                                    break;
                                case TextureWrapMode.Mirror:
                                    inlineSamplerIndex += 2;
                                    break;
                                case TextureWrapMode.MirrorOnce:
                                    inlineSamplerIndex += 3;
                                    break;
                            }
                        }

                        // Replace the token on the following line
                        lines[i+1] = lines[i+1].Replace(args[0], InlineSamplerStateNames[inlineSamplerIndex]);
                    }
                }
                else if (lineTrimmed.StartsWith("//KSODuplicateTextureCheckStart"))
                {
                    // Since files are not fully parsed and instead loosely processed, each shader function needs to have
                    // its sampled texture list reset somewhere before KSODuplicateTextureChecks are made.
                    // As long as textures are sampled in-order inside a single function, this method will work.
                    uniqueSampledTextures = new List<TextureProperty>();
                }
                else if (lineTrimmed.StartsWith("////KSODuplicateTextureCheck")) // not needed for this shader because of sharing locked shaders
                {
                    // Each KSODuplicateTextureCheck line gets evaluated when the shader is optimized
                    // If the texture given has already been sampled as another texture (i.e. one texture is used in two slots)
                    // AND has been sampled with the same UV mode - as indicated by a convention UV property,
                    // AND has been sampled with the exact same Tiling/Offset values
                    // AND has been logged by KSODuplicateTextureCheck, 
                    // then the variable corresponding to the first instance of that texture being 
                    // sampled will be assigned to the variable corresponding to the given texture.
                    // The compiler will then skip the duplicate texture sample since its variable is overwritten before being used
                    
                    // Parse line for argument texture property name
                    string lineParsed = lineTrimmed.Replace(" ", "").Replace("\t", "");
                    int firstParenthesis = lineParsed.IndexOf('(');
                    int lastParenthesis = lineParsed.IndexOf(')');
                    string argName = lineParsed.Substring(firstParenthesis+1, lastParenthesis-firstParenthesis-1);
                    // Check if texture property by argument name exists and has a texture assigned
                    if (Array.Exists(props, x => x.name == argName))
                    {
                        MaterialProperty argProp = Array.Find(props, x => x.name == argName);
                        if (argProp.textureValue != null)
                        {
                            // If no convention UV property exists, sampled UV mode is assumed to be 0 
                            // Any UV enum or mode indicator can be used for this
                            int UV = 0;
                            if (Array.Exists(props, x => x.name == argName + "UV"))
                                UV = (int)(Array.Find(props, x => x.name == argName + "UV").floatValue);

                            Vector2 texScale = material.GetTextureScale(argName);
                            Vector2 texOffset = material.GetTextureOffset(argName);

                            // Check if this texture has already been sampled
                            if (uniqueSampledTextures.Exists(x => (x.texture == argProp.textureValue) 
                                                               && (x.uv == UV)
                                                               && (x.scale == texScale)
                                                               && x.offset == texOffset))
                            {
                                string texName = uniqueSampledTextures.Find(x => (x.texture == argProp.textureValue) && (x.uv == UV)).name;
                                // convention _var variables requried. i.e. _MainTex_var and _CoverageMap_var
                                lines[i] = argName + "_var = " + texName + "_var;";
                            }
                            else
                            {
                                // Texture/UV/ST combo hasn't been sampled yet, add it to the list
                                TextureProperty tp = new TextureProperty();
                                tp.name = argName;
                                tp.texture = argProp.textureValue;
                                tp.uv = UV;
                                tp.scale = texScale;
                                tp.offset = texOffset;
                                uniqueSampledTextures.Add(tp);
                            }
                        }
                    }
                }
                else if (lineTrimmed.StartsWith("[maxtessfactor("))
                {
                    MaterialProperty maxTessFactorProperty = Array.Find(props, x => x.name == TessellationMaxFactorPropertyName);
                    if (maxTessFactorProperty != null)
                    {
                        float maxTessellation = maxTessFactorProperty.floatValue;
                        MaterialProperty maxTessFactorAnimatedProperty = Array.Find(props, x => x.name == TessellationMaxFactorPropertyName + AnimatedPropertySuffix);
                        if (maxTessFactorAnimatedProperty != null && maxTessFactorAnimatedProperty.floatValue == 1)
                            maxTessellation = 64.0f;
                        lines[i] = "[maxtessfactor(" + maxTessellation.ToString(".0######") + ")]";
                    }
                }

                // then replace macros
                foreach (Macro macro in macros)
                {
                    // Expects only one instance of a macro per line!
                    int macroIndex;
                    if ((macroIndex = lines[i].IndexOf(macro.name + "(")) != -1)
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
                            while ((argIndex = newContents.IndexOf(macro.args[j], lastIndex)) != -1)
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
                    while ((constantIndex = lines[i].IndexOf(constant.name, lastIndex)) != -1)
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
                                sb.Append("half(" + constant.value.x.ToString(CultureInfo.InvariantCulture) + ")");
                                break;
                            case PropertyType.Vector:
                                sb.Append("half4("+constant.value.x.ToString(CultureInfo.InvariantCulture)+","
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

                // Then replace grabpass variable names
                foreach (GrabPassReplacement gpr in grabPassVariables)
                {
                    // find indexes of all instances of gpr.originalName that exist on this line
                    int lastIndex = 0;
                    int gbIndex;
                    while ((gbIndex = lines[i].IndexOf(gpr.originalName, lastIndex)) != -1)
                    {
                        lastIndex = gbIndex+1;
                        char charLeft = ' ';
                        if (gbIndex-1 >= 0)
                            charLeft = lines[i][gbIndex-1];
                        char charRight = ' ';
                        if (gbIndex + gpr.originalName.Length < lines[i].Length)
                            charRight = lines[i][gbIndex + gpr.originalName.Length];
                        // Skip invalid matches (probably a subname of another symbol)
                        if (!(Array.Exists(ValidSeparators, x => x == charLeft) && Array.Exists(ValidSeparators, x => x == charRight)))
                            continue;
                        
                        // Replace with new variable name
                        // This could technically be more efficient by being outside the IndexOf loop
                        StringBuilder sb = new StringBuilder(lines[i].Length * 2);
                        sb.Append(lines[i], 0, gbIndex);
                        sb.Append(gpr.newName);
                        sb.Append(lines[i], gbIndex+gpr.originalName.Length, lines[i].Length-gbIndex-gpr.originalName.Length);
                        lines[i] = sb.ToString();
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
                        while ((nameIndex = lines[i].IndexOf(animPropName, lastIndex)) != -1)
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
                            sb.Append(animPropName + "_" + material.GetTag("AnimatedParametersSuffix", false, ""));
                            sb.Append(lines[i], nameIndex+animPropName.Length, lines[i].Length-nameIndex-animPropName.Length);
                            lines[i] = sb.ToString();
                        }
                    }
            }
        }

        public static bool Unlock (Material material)
        {
            // If the material has the unique properties feature enabled, get a list of names of all animated properties
            // using that suffix.  Once switched to the original shader, get the original material properties and carry over values.
            MaterialProperty[] propsLocked = MaterialEditor.GetMaterialProperties(new UnityEngine.Object[] { material });
            MaterialProperty useUniquePropertyNames = Array.Find(propsLocked, x => x.name == ReplaceAnimatedParametersPropertyName);
            List<MaterialProperty> animProps = new List<MaterialProperty>();
            string animatedParameterSuffix = "";
            if (useUniquePropertyNames != null && useUniquePropertyNames.floatValue == 1)
            {
                animatedParameterSuffix = material.GetTag("AnimatedParametersSuffix", false, "");
                foreach (MaterialProperty mp in propsLocked)
                    if (mp.name.EndsWith(animatedParameterSuffix)) animProps.Add(mp);
            }

            // Revert to original shader
            string originalShaderName = ShaderEditor.litShaderName;
            if (originalShaderName == "")
            {
                Debug.LogError("[Kaj Shader Optimizer] Original shader not saved to material, could not unlock shader");
                return false;
            }
            Shader orignalShader = Shader.Find(originalShaderName);
            if (orignalShader == null)
            {
                Debug.LogError("[Kaj Shader Optimizer] Original shader " + originalShaderName + " could not be found");
                return false;
            }

            // For some reason when shaders are swapped on a material the RenderType override tag gets completely deleted and render queue set back to -1
            // So these are saved as temp values and reassigned after switching shaders
            string renderType = material.GetTag("RenderType", false, "");
            int renderQueue = material.renderQueue;
            material.shader = orignalShader;
            material.SetOverrideTag("RenderType", renderType);
            material.renderQueue = renderQueue;

            // Carry over unique generated aniamted prop values from locked-in material to original names
            MaterialProperty[] propsUnlocked = MaterialEditor.GetMaterialProperties(new UnityEngine.Object[] { material });
            foreach (MaterialProperty animProp in animProps)
            {
                MaterialProperty originalProp = Array.Find(propsUnlocked, x => x.name == animProp.name.Substring(0, animProp.name.Length-animatedParameterSuffix.Length));
                switch (animProp.type)
                {
                    case MaterialProperty.PropType.Color:
                        originalProp.colorValue = animProp.colorValue;
                        break;
                    case MaterialProperty.PropType.Vector:
                        originalProp.vectorValue = animProp.vectorValue;
                        break;
                    case MaterialProperty.PropType.Float:
                    case MaterialProperty.PropType.Range:
                        originalProp.floatValue = animProp.floatValue;
                        break;
                    case MaterialProperty.PropType.Texture:
                        originalProp.textureValue = animProp.textureValue;
                        break;
                }
            }
            return true;
        }

        public static void CleanUpLockedShaders(Material material)
        {
            // Delete the variants folder and all files in it, as to not orhpan files and inflate Unity project
            string shaderDirectory = material.GetTag("OptimizedShaderFolder", false, "");
            if (shaderDirectory == "")
                Debug.LogWarning("[Kaj Shader Optimizer] Optimized shader folder could not be found, not deleting anything");
            else
            {
                string materialFilePath = AssetDatabase.GetAssetPath(material);
                //string materialFolder = Path.GetDirectoryName(materialFilePath);
                string newShaderDirectory = "Assets/OptimizedShaders/" + shaderDirectory;
                // Both safe ways of removing the shader make the editor GUI throw an error, so just don't refresh the
                // asset database immediately
                //AssetDatabase.DeleteAsset(shaderFilePath);
                FileUtil.DeleteFileOrDirectory(newShaderDirectory + "/");
                FileUtil.DeleteFileOrDirectory(newShaderDirectory + ".meta");
                //AssetDatabase.Refresh();
            }
        }
    }
}