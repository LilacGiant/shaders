using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace z3y.ShaderGenerator
{

    public class ShaderGenerator
    {
        private static readonly string GeneratorKey = "zzuvLsxpagBqqELE";
        private static readonly string OriginalShaderTag = "OriginalShaderTag";


        [MenuItem("Tools/Shader Generator/Lock")]
        public static void GenerateShader()
        {
            Material[] mats = GetMaterialsUsingGenerator();

            int sharedCount = 0;

            float progress = mats.Length;
            AssetDatabase.StartAssetEditing();
            for (int i = 0; i < mats.Length; i++)
            {
                EditorUtility.DisplayCancelableProgressBar("Generating Shaders", mats[i].name, i/progress);
                LockMaterial(mats[i]);

            }

            EditorUtility.ClearProgressBar();
            AssetDatabase.StopAssetEditing();
            AssetDatabase.Refresh();

            for (int i = 0; i < mats.Length; i++)
            {
                EditorUtility.DisplayCancelableProgressBar("Replacing Shaders", mats[i].name, i/progress);

                LockApplyShader(mats[i]);
                mats[i].SetFloat(GeneratorKey,1);

                
            }
            
            EditorUtility.ClearProgressBar();

            Debug.Log($"[<Color=fuchsia>ShaderOptimizer</Color>] Locked <b>{mats.Length}</b> Materials. Generated <b>{mats.Length-sharedCount}</b> shaders.");

        }

        [MenuItem("Tools/Shader Generator/Unlock Materials")]
        public static void UnlockAllMaterials()
        {
            Material[] mats = GetMaterialsUsingGenerator(true);

            foreach (Material m in mats)
            {
                Unlock(m);
                m.SetFloat(GeneratorKey, 0);
            }
        }

        public static void LockMaterial(Material m)
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

                switch(mp.type)
                {
                    case MaterialProperty.PropType.Float:
                    case MaterialProperty.PropType.Range:
                        propDefines.Append($"#define {mp.name} float({mp.floatValue})");
                        break;
                    case MaterialProperty.PropType.Vector:
                        propDefines.Append($"#define {mp.name} float4{mp.vectorValue}");
                        break;
                    case MaterialProperty.PropType.Color:
                        string value = mp.colorValue.ToString();
                        value = value.Remove(0, 4);
                        propDefines.Append($"#define {mp.name} float4{value}");
                        break;
                    case MaterialProperty.PropType.Texture:
                        if(mp.textureValue != null)
                        {
                            propDefines.Append($"#define PROP{mp.name.ToUpper()}");
                            propDefines.Append(Environment.NewLine);
                            
                            Texture t = mp.textureValue;
                            Vector4 texelSize = new Vector4(1f/t.width, 1f/t.height, t.width, t.height);
                            propDefines.Append($"#define {mp.name}_TexelSize float4{texelSize.ToString("0.00000")}");
                            propDefines.Append(Environment.NewLine);
                        }
                        else
                        {
                            propDefines.Append($"#define {mp.name}_TexelSize float4(1.0, 1.0, 1.0, 1.0)");
                            propDefines.Append(Environment.NewLine);
                        }
                        propDefines.Append($"#define {mp.name}_ST float4{mp.textureScaleAndOffset.ToString("0.00000")}");
                        break;

                }

                propDefines.Append(Environment.NewLine);
            }

            string[] shaderKeywords = m.shaderKeywords;
            string materialGUID = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(m));


            string shaderFile;
            StreamReader sr = new StreamReader(shaderPath);
            shaderFile = sr.ReadToEnd();
            sr.Close();

            string[] fileLines = Regex.Split(shaderFile, "\r\n|\r|\n");

            StringBuilder newShader = new StringBuilder();

            for (int i = 0; i < fileLines.Length; i++)
            {
                string currentLine = fileLines[i];
                string trimmedLine = fileLines[i].TrimStart();

                if(trimmedLine.StartsWith("Shader", StringComparison.Ordinal))
                {
                    currentLine = $"Shader \"Hidden/Locked/{shader.name}/{materialGUID}\"";
                }
                else if(trimmedLine.StartsWith("#pragma shader_feature_local", StringComparison.Ordinal))
                {
                    string[] lineFeatures = trimmedLine.Replace("#pragma shader_feature_local", string.Empty).Split(null);

                    string lineFeature = string.Empty;
                    foreach (var feature in lineFeatures)
                    {
                        if(feature == string.Empty) continue;

                        if(shaderKeywords.Contains(feature))
                        {
                            lineFeature = feature;
                        }
                    }

                    currentLine = lineFeature.Equals(string.Empty) ? "//" + currentLine : "#define " + lineFeature;

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

                newShader.Append(currentLine);
                newShader.Append(Environment.NewLine);
            }

            // Debug.Log(propDefines);
            Debug.Log(newShader);
            Debug.Log(shaderPath);


            string oldShaderFileName = Regex.Split(shaderPath, "/").Last();

            string newShaderPath = shaderPath.Replace(oldShaderFileName, string.Empty) + "Generated_" + materialGUID + oldShaderFileName;
            Debug.Log(newShaderPath);

            StreamWriter sw = new StreamWriter(newShaderPath);
            sw.Write(newShader);
            sw.Close();

            ReplaceStruct replaceStruct = new ReplaceStruct();

            replaceStruct.Material = m;
            replaceStruct.Shader = shader;
            replaceStruct.SmallGuid = materialGUID;
            replaceStruct.NewShaderPath = newShaderPath;
            ReplaceStructs.Add(m, replaceStruct);
        }

        public static void Unlock (Material material)
        {
            if(!material.shader.name.StartsWith("Hidden/"))
            {
                material.SetFloat(GeneratorKey, 0);
                return;
            }
            string originalShaderName = material.GetTag(OriginalShaderTag, false, string.Empty);

            Shader orignalShader = Shader.Find(originalShaderName);
            if (orignalShader is null)
            {
                Debug.LogError("[Shader Optimizer] Original shader " + originalShaderName + " not found");
                return;
            }

            string renderType = material.GetTag("RenderType", false, string.Empty);
            int renderQueue = material.renderQueue;
            material.shader = orignalShader;
            material.SetOverrideTag("RenderType", renderType);
            material.renderQueue = renderQueue;
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
            replaceStruct.Material.SetOverrideTag(OriginalShaderTag, replaceStruct.Shader.name);
            replaceStruct.Material.SetOverrideTag("OptimizedShaderFolder", replaceStruct.SmallGuid);

            string renderType = replaceStruct.Material.GetTag("RenderType", false, string.Empty);
            int renderQueue = replaceStruct.Material.renderQueue;

            Shader newShader = AssetDatabase.LoadAssetAtPath<Shader>(replaceStruct.NewShaderPath);
            
            replaceStruct.Material.shader = newShader;
            replaceStruct.Material.SetOverrideTag("RenderType", renderType);
            replaceStruct.Material.renderQueue = renderQueue;

            // Remove ALL keywords

            foreach (string keyword in replaceStruct.Material.shaderKeywords)
                replaceStruct.Material.DisableKeyword(keyword);


            return true;
        }

        public static bool HasGeneratorKey(Shader shader)
        {
            bool a = false;
            try 
            {
                a = ShaderUtil.GetPropertyName(shader, 0) == GeneratorKey;
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
                    if(!materials.Contains(mat) && HasGeneratorKey(mat.shader))
                        if(mat.GetFloat(GeneratorKey) == (isLocked ? 1 : 0))
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

    
}
