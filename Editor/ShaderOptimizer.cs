using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEditor.Build;
using UnityEngine;
using Object = UnityEngine.Object;
using UnityEngine.SceneManagement;
using UnityEditor.Rendering;
using HarmonyLib;
using System.Reflection;


#if VRC_SDK_VRCSDK2
using VRCSDK2;
#endif
#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
using VRC.SDKBase.Editor.BuildPipeline;
#endif

namespace z3y.Shaders
{
    

    public class Optimizer
    {
        public static readonly string lockKey = "zzuvLsxpagBqqELE";
        private static readonly string OriginalShaderTag = "OriginalShaderTag";
        private static readonly string AnimatedPropertySuffix = "Animated";

        
        private static Dictionary<Material, ReplaceStruct> ReplaceDictionary = new Dictionary<Material, ReplaceStruct>();
        private static Dictionary<string, Material> MaterialPropertyDefines = new Dictionary<string, Material>();
        private static int SharedMaterialCount = 0;

        const string HARMONY_ID = "z3y.Shaders.Optimizer";

        [MenuItem("Tools/Shader Optimizer/Lock")]
        public static void LockAllMaterials()
        {
            Material[] mats = GetMaterialsUsingGenerator();
            
            // using harmony to patch MaterialEditor.ApplyMaterialPropertyDrawer because material.Shader = newShader calls it and its really slow
            Harmony harmony = new Harmony(HARMONY_ID);
            MethodInfo ApplyMaterialPropertyDrawersMethod = typeof(MaterialEditor).GetMethods(BindingFlags.Public | BindingFlags.Static).First(e => e.Name == "ApplyMaterialPropertyDrawers");
            HarmonyMethod ApplyMaterialPropertyDrawersDisabler = new HarmonyMethod(typeof(InjectedMethods).GetMethod(nameof(InjectedMethods.ApplyMaterialPropertyDrawersDisabler)));
            harmony.Patch(ApplyMaterialPropertyDrawersMethod, ApplyMaterialPropertyDrawersDisabler);

            AssetDatabase.StartAssetEditing();

            for (int i = 0; i < mats.Length; i++)
            {
                Lock(mats[i]);

            }

            AssetDatabase.StopAssetEditing();
            AssetDatabase.Refresh();

            AssetDatabase.StartAssetEditing();
            for (int i = 0; i < mats.Length; i++)
            {
                UnityEngine.Profiling.Profiler.BeginSample("My Sample");
                LockApplyShader(mats[i]);
                mats[i].SetFloat(lockKey,1);
                UnityEngine.Profiling.Profiler.EndSample();

            }
            AssetDatabase.StopAssetEditing();

            Debug.Log($"[<Color=fuchsia>ShaderOptimizer</Color>] Locked <b>{mats.Length}</b> Materials. Generated {mats.Length-SharedMaterialCount} shaders");
            ReplaceDictionary.Clear();
            MaterialPropertyDefines.Clear();
            SharedMaterialCount = 0;
            harmony.UnpatchAll(HARMONY_ID);
        }

        public static void LockMaterial(Material m)
        {
            Lock(m, false);
            m.SetFloat(lockKey,1);
        }

        [MenuItem("Tools/Shader Optimizer/Unlock")]
        public static void UnlockAllMaterials()
        {
            Material[] mats = GetMaterialsUsingGenerator(true);

            foreach (Material m in mats)
            {
                Unlock(m);
                m.SetFloat(lockKey, 0);
            }
        }

        public static void Lock(Material m, bool replaceLater = true)
        {
            Shader shader = m.shader;
            string shaderPath = AssetDatabase.GetAssetPath(shader);


            MaterialProperty[] props = MaterialEditor.GetMaterialProperties(new UnityEngine.Object[] { m });
            int propertyCount = ShaderUtil.GetPropertyCount(shader);

            StringBuilder propDefines = new StringBuilder("#define OPTIMIZER_ENABLED");
            propDefines.Append(Environment.NewLine);
            propDefines.Append("#define PROPERTIES_DEFINED");
            propDefines.Append(Environment.NewLine);


            for (int i = 1; i < propertyCount; i++)
            {
                string propName = ShaderUtil.GetPropertyName(m.shader, i);
                MaterialProperty mp = System.Array.Find(props, x => x.name == propName);

                bool isAnimated = IsAnimated(m, propName, props);

                switch(mp.type)
                {
                    case MaterialProperty.PropType.Float:
                    case MaterialProperty.PropType.Range:
                        if(isAnimated)
                        {
                            propDefines.Append($"float {mp.name};");
                            break;
                        }
                        propDefines.Append($"#define {mp.name} float({mp.floatValue})");
                        break;
                        
                    case MaterialProperty.PropType.Vector:
                        if(isAnimated)
                        {
                            propDefines.Append($"float4 {mp.name};");
                            break;
                        }
                        propDefines.Append($"#define {mp.name} float4{mp.vectorValue}");
                        break;

                    case MaterialProperty.PropType.Color:
                        if(isAnimated)
                        {
                            propDefines.Append($"float4 {mp.name};");
                            break;
                        }
                        Color value;

                        if ((mp.flags & MaterialProperty.PropFlags.HDR) != 0)
                        {
                            if ((mp.flags & MaterialProperty.PropFlags.Gamma) != 0) value = mp.colorValue.linear;
                            else value = mp.colorValue;
                        }
                        else if ((mp.flags & MaterialProperty.PropFlags.Gamma) != 0) value = mp.colorValue;
                        else value = mp.colorValue.linear;

                        string colorValue = value.ToString().Remove(0,4);
                        propDefines.Append($"#define {mp.name} float4{colorValue}");
                        break;

                    case MaterialProperty.PropType.Texture:
                        if(mp.textureValue != null)
                        {
                            propDefines.Append($"#define PROP{mp.name.ToUpper()}");
                            propDefines.Append(Environment.NewLine);

                            bool texelSizeAnimated = IsAnimated(m, propName + "_TexelSize", props);
                            if(texelSizeAnimated)
                            {
                                propDefines.Append($"float4 {mp.name}_TexelSize;");
                                propDefines.Append(Environment.NewLine);
                            }
                            else
                            {
                                Texture t = mp.textureValue;
                                Vector4 texelSize = new Vector4(1f/t.width, 1f/t.height, t.width, t.height);
                                propDefines.Append($"#define {mp.name}_TexelSize float4{texelSize.ToString("0.00000")}");
                                propDefines.Append(Environment.NewLine);
                            }
                        }
                        else
                        {
                            propDefines.Append($"#define {mp.name}_TexelSize float4(1.0, 1.0, 1.0, 1.0)");
                            propDefines.Append(Environment.NewLine);
                        }
                        bool STAnimated = IsAnimated(m, propName + "_ST", props);
                        if(STAnimated) propDefines.Append($"float4 {mp.name}_ST;");
                        else propDefines.Append($"#define {mp.name}_ST float4{mp.textureScaleAndOffset.ToString("0.00000")}");
                        break;
                }

                propDefines.Append(Environment.NewLine);
            }

            string[] shaderKeywords = m.shaderKeywords;
            string materialGUID = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(m));

            Material sharedMaterial = null;
            string propertyKeys = propDefines + String.Join(" ", shaderKeywords);
            if(replaceLater)
            {
                if (MaterialPropertyDefines.ContainsKey(propertyKeys))
                {
                    MaterialPropertyDefines.TryGetValue(propertyKeys, out sharedMaterial);
                }
                else
                {
                    MaterialPropertyDefines.Add(propertyKeys, m);
                }
            }
            ReplaceStruct replaceStruct = new ReplaceStruct();

            if(sharedMaterial != null)
            {
                string sharedoldShaderFileName = Regex.Split(AssetDatabase.GetAssetPath(sharedMaterial.shader), "/").Last();
                string sharedmaterialGUID = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(sharedMaterial));
                SharedMaterialCount++;
                replaceStruct.Material = m;
                replaceStruct.Shader = sharedMaterial.shader;
                replaceStruct.GUID = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(sharedMaterial));
                replaceStruct.NewShaderPath = shaderPath.Replace(sharedoldShaderFileName, string.Empty) + "Generated_" + sharedmaterialGUID + "_" + sharedoldShaderFileName;
                ReplaceDictionary.Add(m, replaceStruct);
                return;
            }


            string shaderFile;
            StreamReader sr = new StreamReader(shaderPath);
            shaderFile = sr.ReadToEnd();
            sr.Close();

            string[] fileLines = Regex.Split(shaderFile, "\r\n|\r|\n");

            fileLines[0] = $"Shader \"Hidden/Locked/{shader.name}/{materialGUID}\"";
            
            StringBuilder newShader = new StringBuilder();

            bool isRemoving = false;
            string[] propertyName = null;
            for (int i = 0; i < fileLines.Length; i++)
            {
                string trimmedLine = fileLines[i].TrimStart();

                
                if(trimmedLine.StartsWith("//RemoveIfZero_", StringComparison.Ordinal) || isRemoving)
                {
                    fileLines[i] = string.Empty;
                    if(!isRemoving) propertyName = Regex.Split(trimmedLine, "_");
  
                    if(m?.GetFloat("_" + propertyName[1]) == 0)
                    {
                        
                        if(!isRemoving)
                        {
                            if(trimmedLine.StartsWith("//RemoveIfZero_" + propertyName[1])) isRemoving = true;
                        }
                        else if(trimmedLine.StartsWith("//RemoveIfZero_" + propertyName[1])) isRemoving = false;

                        if(isRemoving) continue;
                    }
                }
                if(trimmedLine.StartsWith("//RemoveIfOne_", StringComparison.Ordinal) || isRemoving)
                {
                    fileLines[i] = string.Empty;
                    if(!isRemoving) propertyName = Regex.Split(trimmedLine, "_");
  
                    if(m?.GetFloat("_" + propertyName[1]) == 1)
                    {
                        
                        if(!isRemoving)
                        {
                            if(trimmedLine.StartsWith("//RemoveIfOne_" + propertyName[1])) isRemoving = true;
                        }
                        else if(trimmedLine.StartsWith("//RemoveIfOne_" + propertyName[1])) isRemoving = false;

                        if(isRemoving) continue;
                    }
                }
                else if(trimmedLine.StartsWith("#pragma shader_feature", StringComparison.Ordinal))
                {
                    string[] lineFeatures = trimmedLine.Split();

                    string lineFeature = string.Empty;

                    for (int j = 2; j < lineFeatures.Length; j++)
                    {
                        if(lineFeatures[j] == string.Empty) continue;

                        if(shaderKeywords.Contains(lineFeatures[j]))
                        {
                            lineFeature = lineFeatures[j];
                        }
                    }

                    fileLines[i] = lineFeature.Equals(string.Empty) ? "//" + fileLines[i] : "#define " + lineFeature;

                }
                else if(trimmedLine.StartsWith("SubShader", StringComparison.Ordinal))
                {
                    newShader.Append(Environment.NewLine);
                    newShader.Append("CGINCLUDE");
                    newShader.Append(Environment.NewLine);
                    newShader.Append(propDefines);
                    newShader.Append("ENDCG");
                    newShader.Append(Environment.NewLine);
                    newShader.Append(Environment.NewLine);   
                }
                


                newShader.Append(fileLines[i]);
                newShader.Append(Environment.NewLine);
            }


            string oldShaderFileName = Regex.Split(shaderPath, "/").Last();

            string newShaderPath = shaderPath.Replace(oldShaderFileName, string.Empty) + "Generated_" + materialGUID + "_" + oldShaderFileName;

            StreamWriter sw = new StreamWriter(newShaderPath);
            sw.Write(newShader);
            sw.Close();


            replaceStruct.Material = m;
            replaceStruct.Shader = shader;
            replaceStruct.GUID = materialGUID;
            replaceStruct.NewShaderPath = newShaderPath;

            if(!replaceLater)
            {
                AssetDatabase.Refresh();
                ReplaceShader(replaceStruct);
                return;
            }

            ReplaceDictionary.Add(m, replaceStruct);
        }

        private static bool IsAnimated(Material m, string propName, MaterialProperty[] props)
        {
            bool isAnimated = !m.GetTag(propName + AnimatedPropertySuffix, false).Equals(string.Empty, StringComparison.Ordinal);
            if(!isAnimated)
            {
                MaterialProperty animatedProp = Array.Find(props, x => x.name == propName + AnimatedPropertySuffix);
                if (animatedProp != null) isAnimated = animatedProp.floatValue == 1;
            }
            return isAnimated;
        }

        public static void Unlock (Material material)
        {
            if(!material.shader.name.StartsWith("Hidden/"))
            {
                material.SetFloat(lockKey, 0);
                return;
            }
            string originalShaderName = material.GetTag(OriginalShaderTag, false, string.Empty);

            Shader orignalShader = Shader.Find(originalShaderName);
            if (orignalShader is null)
            {
                Debug.LogError("[<Color=fuchsia>ShaderOptimizer</Color>] Original shader " + originalShaderName + " not found");
                return;
            }

            string renderType = material.GetTag("RenderType", false, string.Empty);
            int renderQueue = material.renderQueue;
            material.shader = orignalShader;
            material.SetOverrideTag("RenderType", renderType);
            material.renderQueue = renderQueue;
        }


        private struct ReplaceStruct
        {
            public Material Material;
            public Shader Shader;
            public string GUID;
            public string NewShaderPath;
        }

        private static void LockApplyShader(Material material)
        {
            if (ReplaceDictionary.ContainsKey(material) == false) return;
            ReplaceStruct applyStruct = ReplaceDictionary[material];
            ReplaceDictionary.Remove(material);

            ReplaceShader(applyStruct);
        }
        
        private static bool ReplaceShader(ReplaceStruct replaceStruct)
        {
            replaceStruct.Material.SetOverrideTag(OriginalShaderTag, replaceStruct.Shader.name);
            replaceStruct.Material.SetOverrideTag("OptimizedShaderFolder", replaceStruct.GUID);

            string renderType = replaceStruct.Material.GetTag("RenderType", false, string.Empty);
            int renderQueue = replaceStruct.Material.renderQueue;
            
            Shader newShader = AssetDatabase.LoadAssetAtPath<Shader>(replaceStruct.NewShaderPath);
            
            replaceStruct.Material.shader = newShader;
            replaceStruct.Material.SetOverrideTag("RenderType", renderType);
            replaceStruct.Material.renderQueue = renderQueue;

            foreach (string keyword in replaceStruct.Material.shaderKeywords)
            {
                replaceStruct.Material.DisableKeyword(keyword);
            }


            return true;
        }


        public static bool HaslockKey(Shader shader)
        {
            bool a = false;
            try 
            {
                a = ShaderUtil.GetPropertyName(shader, 0) == lockKey;
            }
            catch { }
            return a;
        }

        public static Material[] GetMaterialsUsingGenerator(bool isLocked = false)
        {
            List<Material> materials = new List<Material>();
            List<Material> foundMaterials = new List<Material>();
            Scene scene = SceneManager.GetActiveScene();

            string[] materialPaths = AssetDatabase.GetDependencies(scene.path).Where(x => x.EndsWith(".mat")).ToArray();
            var renderers = UnityEngine.Object.FindObjectsOfType<Renderer>();

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
                    if(!materials.Contains(mat) && HaslockKey(mat.shader))
                        if(mat.GetFloat(lockKey) == (isLocked ? 1 : 0))
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
    }

    public class InjectedMethods
    {
        public static bool ApplyMaterialPropertyDrawersDisabler(Material material) => false;
    }
    

#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
    public class LockAllMaterialsOnVRCWorldUpload : IVRCSDKBuildRequestedCallback
    {
        public int callbackOrder => 69;

        bool IVRCSDKBuildRequestedCallback.OnBuildRequested(VRCSDKRequestedBuildType requestedBuildType)
        {
            #if !UNITY_ANDROID
                Optimizer.LockAllMaterials();
            #endif
            return true;
        }
    }
#endif

    public class StripUnlocked : IPreprocessShaders
    {
        public int callbackOrder => 69;

        public void OnProcessShader(Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> data)
        {
            bool shouldStrip = Optimizer.HaslockKey(shader) && !shader.name.StartsWith("Hidden/Locked/");

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
            Optimizer.UnlockAllMaterials();
        }
    }
    
}
