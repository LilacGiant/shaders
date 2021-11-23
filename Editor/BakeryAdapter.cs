using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace z3y.Shaders
{
    public class BakeryAdapter
    {
        
        #if BAKERY_INCLUDED
        [MenuItem("Tools/Shader Optimizer/Generate Bakery Materials")]
        public static void HandleBakeryPropertyBlocks()
        {
            const string newMaterialPath = "Assets/GeneratedMaterials/";
            if (!Directory.Exists(newMaterialPath)) Directory.CreateDirectory(newMaterialPath);

            MeshRenderer[] mr = UnityEngine.Object.FindObjectsOfType<MeshRenderer>();
            Dictionary<string, Material> generatedMaterialList = new Dictionary<string, Material>();

            int materialsCount = 0;
            

            for (int i = 0; i < mr.Length; i++)
            {
                EditorUtility.DisplayCancelableProgressBar("Generating Materials", mr[i].name, (float)i/mr.Length);
                MaterialPropertyBlock propertyBlock = new MaterialPropertyBlock();
                mr[i].GetPropertyBlock(propertyBlock);
                Texture RNM0 = propertyBlock.GetTexture("_RNM0");
                Texture RNM1 = propertyBlock.GetTexture("_RNM1");
                Texture RNM2 = propertyBlock.GetTexture("_RNM2");
                int propertyLightmapMode = (int)propertyBlock.GetFloat("bakeryLightmapMode");

                if(RNM0 && RNM1 && RNM2 && propertyLightmapMode != 0)
                {
                    Material[] newSharedMaterials = new Material[mr[i].sharedMaterials.Length];

                    for (int j = 0; j < mr[i].sharedMaterials.Length; j++)
                    {
                        Material material = mr[i].sharedMaterials[j];

                        if(material != null)
                        {
                            bool usingOptimizer = false;
                            try 
                            {
                                usingOptimizer = ShaderUtil.GetPropertyName(material.shader, 0).Equals(Optimizer.lockKey);
                            }
                            catch {}
                            
                            if  (usingOptimizer && material.GetTag("OriginalMaterialPath", false).Equals(string.Empty) && (material.shaderKeywords.Contains("BAKERY_SH") || material.shaderKeywords.Contains("BAKERY_RNM")))

                            {
                                string materialPath = AssetDatabase.GetAssetPath(material);
                                string textureName = AssetDatabase.GetAssetPath(RNM0) + "_" + AssetDatabase.GetAssetPath(RNM1) + "_" + AssetDatabase.GetAssetPath(RNM2);
                                string matTexHash = ComputeMD5(materialPath + textureName);


                                Material newMaterial;

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
                                    materialsCount ++;

                                    
                                    try
                                    {
                                        AssetDatabase.CreateAsset(newMaterial, newMaterialPath + matTexHash + ".mat");
                                    }
                                    catch(Exception e)
                                    {
                                        Debug.LogError($"Unable to create new material {newMaterial.name} for {mr} {e}");
                                    }

                                }

                                newSharedMaterials[j] = newMaterial;

                            }
                            else if (material != null)
                            {
                                newSharedMaterials[j] = material;
                            }
                        }
                    }

                    mr[i].sharedMaterials = newSharedMaterials;
                }
            }
            EditorUtility.ClearProgressBar();
            AssetDatabase.Refresh();
            Debug.Log($"[<Color=fuchsia>ShaderOptimizer</Color>] Generated <b>{materialsCount}</b> Materials.");
        }


        [MenuItem("Tools/Shader Optimizer/Revert Bakery Materials")]
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
                            string originalMatPath = rend.sharedMaterials[i].GetTag("OriginalMaterialPath", false, string.Empty);
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
        #endif

        // https://forum.unity.com/threads/hash-function-for-game.452779/
        private static string ComputeMD5(string str)
        {
            ASCIIEncoding encoding = new ASCIIEncoding();
            byte[] bytes = encoding.GetBytes(str);
            var sha = new MD5CryptoServiceProvider();
            return BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-", "").ToLower();
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
    }
}
