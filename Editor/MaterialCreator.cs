﻿using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

namespace z3y.MaterialCreator
{
    public class MaterialCreator : Editor
    {
        

        private struct MaskMap
        {
            public Texture2D metallic;
            public string metallicPath;
            public Texture2D occlusion;
            public string occlusionPath;
            public Texture2D smoothness;
            public string smoothnessPath;
            public Texture2D roughness;
            public string roughnessPath;
        }

        private struct PBRTextures
        {
            public Texture2D albedo;
            public Texture2D normal;
            public Texture2D mask;
        }

        [MenuItem("Assets/Create/Lit/Material")]
        private static void GetCurrentPath()
        {
            string[] currentFolder = {AssetDatabase.GUIDToAssetPath(UnityEditor.Selection.assetGUIDs[0])};
            string[] foundTextureGUIDs = AssetDatabase.FindAssets("t:texture", currentFolder);
            if(Selection.assetGUIDs.Length == 1)
            {
                string[] splitCurretFolderName = Regex.Split(currentFolder[0], "/");
                string curretFolderName = splitCurretFolderName[splitCurretFolderName.Length-1];
                string[] foundTexturePaths = new string[foundTextureGUIDs.Length];
                string[] foundTextureNames = new string[foundTextureGUIDs.Length];
                for (int i = 0; i < foundTextureGUIDs.Length; i++)
                {
                    foundTexturePaths[i] = AssetDatabase.GUIDToAssetPath(foundTextureGUIDs[i]);
                    string[] splitPath = Regex.Split(foundTexturePaths[i], "/");
                    foundTextureNames[i] = splitPath[splitPath.Length-1];
                }

                PBRTextures pbr = new PBRTextures();
                MaskMap mask = new MaskMap();
                for (int i = 0; i < foundTextureNames.Length; i++)
                {
                    string t = foundTextureNames[i].ToLower();

                    if(t.Contains("albedo") || t.Contains("color") || t.Contains("diff"))
                        pbr.albedo = LoadTexture(foundTexturePaths[i]);
                    if(t.Contains("normal"))
                    {
                        pbr.normal = LoadTexture(foundTexturePaths[i]);

                        TextureImporter tex = (TextureImporter)UnityEditor.AssetImporter.GetAtPath(foundTexturePaths[i]);
                        tex.textureType = TextureImporterType.NormalMap;
                        tex.SaveAndReimport();
                    }

                    if(t.Contains("mask"))
                    {
                        pbr.mask = LoadTexture(foundTexturePaths[i]);
                    }
                    else 
                    {
                        if(t.Contains("smooth"))
                        {
                            mask.smoothness = LoadTexture(foundTexturePaths[i]);
                            mask.smoothnessPath = foundTexturePaths[i];
                        }
                        if(t.Contains("rough"))
                        {
                            mask.roughness = LoadTexture(foundTexturePaths[i]);
                            mask.roughnessPath = foundTexturePaths[i];
                        }
                        if(t.Contains("occlusion"))
                        {
                            mask.occlusion = LoadTexture(foundTexturePaths[i]);
                            mask.occlusionPath = foundTexturePaths[i];
                        }
                        if(t.Contains("metall"))
                        {
                            mask.metallic = LoadTexture(foundTexturePaths[i]);
                            mask.metallicPath = foundTexturePaths[i];
                        }
                    }
                }

                

                Shader shader = Shader.Find("z3y/lit");
                Material mat = new Material(shader);
                mat.name = curretFolderName;
                Debug.Log(mat.name);

                if(pbr.albedo != null) mat.SetTexture("_MainTex", pbr.albedo);
                if(pbr.normal != null)
                {
                    mat.SetTexture("_BumpMap", pbr.normal);
                    mat.SetFloat("_BumpScale", 1);
                }
                if(pbr.mask != null)
                {
                    mat.SetTexture("_MetallicGlossMap", pbr.mask);
                    mat.SetFloat("_Metallic", 1);
                    mat.SetFloat("_Glossiness", 1);
                    mat.SetFloat("_Occlusion", 1);
                }
                else
                {
                    ChannelTexture redChannel = new ChannelTexture("Red", 0);
                    ChannelTexture greenChannel = new ChannelTexture("Green", 0);
                    ChannelTexture blueChannel = new ChannelTexture("Blue", 0);
                    ChannelTexture alphaChannel = new ChannelTexture("Alpha", 0);

                    if(mask.metallic != null)
                    {
                        UncompressTexture(mask.metallicPath);
                        redChannel.texture = mask.metallic;
                        mat.SetFloat("_Metallic", 1);
                    }
                    if(mask.occlusion != null) 
                    {
                        UncompressTexture(mask.occlusionPath);
                        greenChannel.texture = mask.occlusion;
                        mat.SetFloat("_Occlusion", 1);
                    }
                    if(mask.roughness != null)
                    {
                        UncompressTexture(mask.roughnessPath);
                        alphaChannel.texture = mask.roughness;
                        alphaChannel.invert = true;
                        mat.SetFloat("_Glossiness", 1);
                    }
                    else if(mask.smoothness != null)
                    {
                        UncompressTexture(mask.smoothnessPath);
                        alphaChannel.texture = mask.smoothness;
                        mat.SetFloat("_Glossiness", 1);
                    }

                    int width = pbr.albedo.width;
                    int height = pbr.albedo.height;

                    ChannelTexture[] channelTextures = new ChannelTexture[] {redChannel,greenChannel,blueChannel,alphaChannel};
                    string newTexturePath = ChannelTexture.PackTexture(channelTextures, currentFolder[0], width, height, ChannelTexture.TexEncoding.SaveAsPNG);

                    TextureImporter tex = (TextureImporter)UnityEditor.AssetImporter.GetAtPath(newTexturePath);
                    tex.textureCompression = TextureImporterCompression.Compressed;
                    tex.sRGBTexture = false;
                    tex.SaveAndReimport();

                    pbr.mask = (Texture2D)AssetDatabase.LoadAssetAtPath(newTexturePath, typeof(Texture2D));
                    mat.SetTexture("_MetallicGlossMap", pbr.mask);
                }

                AssetDatabase.CreateAsset(mat, currentFolder[0] + "/" + mat.name + ".mat");

            }
        }

        private static void UncompressTexture(string path)
        {
            TextureImporter tex = (TextureImporter)UnityEditor.AssetImporter.GetAtPath(path);
            tex.textureCompression = TextureImporterCompression.Uncompressed;
            tex.sRGBTexture = true;
            tex.SaveAndReimport();

        }

        private static Texture2D LoadTexture(string path)
        {
            Texture2D t;
            t = (Texture2D)AssetDatabase.LoadAssetAtPath(path, typeof(Texture2D));
            return t;
        }

        [System.Serializable]
        public class ChannelTexture
        {
            public string name;
            public Texture2D texture;
            public bool invert;
            public ColorMode mode = ColorMode.Red;
            public enum ColorMode
            {
                Red,
                Green,
                Blue,
                Alpha
            }

            public void SetMode(int i, bool ignoreSave = false)
            {
                switch (i)
                {
                    case 0:
                        mode = ColorMode.Red;
                        break;
                    case 1:
                        mode = ColorMode.Green;
                        break;
                    case 2:
                        mode = ColorMode.Blue;
                        break;
                    case 3:
                        mode = ColorMode.Alpha;
                        break;
                }
                if (!ignoreSave)
                {
                    EditorPrefs.SetInt("TextureUtilityChannel" + name, i);
                }
            }

            public ChannelTexture(string n, int mode)
            {
                name = n;
                SetMode(mode, true);
            }

            public static string PackTexture(ChannelTexture[] channels, string destination,int width, int height, TexEncoding encodingType, bool refresh=true,bool overwrite=true)
            {
                int firstIndex = -1;
                for (int i = 3; i >= 0; i--)
                {
                    if (channels[i].texture)
                        firstIndex = i;
                }
                if (firstIndex < 0)
                    return string.Empty;

                ChannelTexture firstChannel = channels[firstIndex];

                
                Texture2D newTexture = new Texture2D(width, height);
                channels[0].GetChannelColors(width, height, out float[] reds, true);
                channels[1].GetChannelColors(width, height, out float[] greens, true);
                channels[2].GetChannelColors(width, height, out float[] blues, true);
                channels[3].GetChannelColors(width, height, out float[] alphas, true);
                Color[] finalColors = new Color[width*height];

                for (int i=0;i< finalColors.Length;i++)
                {
                    finalColors[i].r = (reds!=null) ? reds[i] : 0;
                    finalColors[i].g = (greens != null) ? greens[i] : 0;
                    finalColors[i].b = (blues != null) ? blues[i] : 0;
                    finalColors[i].a = (alphas != null) ? alphas[i] : 1;
                }
                newTexture.SetPixels(finalColors);
                newTexture.Apply();

                GetEncoding(newTexture, encodingType, out byte[] data, out string ext);

                string newTexturePath = destination+"/"+System.IO.Path.GetFileNameWithoutExtension(destination)+"_Mask"+ext;
                if (!overwrite)
                    newTexturePath = AssetDatabase.GenerateUniqueAssetPath(newTexturePath);
                SaveTexture(data, newTexturePath);
                DestroyImmediate(newTexture);
                if (refresh)
                    AssetDatabase.Refresh();
                
                return newTexturePath;
            }

            private static void SaveTexture(byte[] textureEncoding, string path)
            {
                System.IO.FileStream stream = System.IO.File.Create(path);
                stream.Write(textureEncoding, 0, textureEncoding.Length);
                stream.Dispose();
            }

            private static string GetDestinationFolder(string path)
            {
                return path.Substring(0, path.LastIndexOf('/'));
            }

            private static TexEncoding encoding = TexEncoding.SaveAsPNG;
            public enum TexEncoding
            {
                SaveAsPNG,
                SaveAsJPG,
                SaveAsTGA
            }
            private static void GetEncoding(Texture2D texture, TexEncoding encodingType, out byte[] data, out string ext)
            {
                switch ((int)encodingType)
                {
                    default:
                        ext = ".png";
                        data = texture.EncodeToPNG();
                        break;
                    case 1:
                        ext = ".jpg";
                        data = texture.EncodeToJPG(75);
                        break;
                    case 2:
                        ext = ".tga";
                        data = texture.EncodeToTGA();
                        break;
                }
            }

            
            public Texture2D GetChannelColors(int width, int height, out float[] colors, bool unloadTempTexture)
            {
                if (!texture)
                {
                    colors = null;
                    return null;
                }
                else
                {
                    Texture2D newTexture = GetColors(texture, width, height, out Color[] myColors, unloadTempTexture);
                    colors = myColors.Select(c =>
                    {
                        if (mode == ColorMode.Red)
                            return c.r;
                        if (mode == ColorMode.Green)
                            return c.g;
                        if (mode == ColorMode.Blue)
                            return c.b;

                        return c.a;
                    }).ToArray();
                    if (invert)
                    {
                        for (int i = 0; i < colors.Length; i++)
                        {
                            colors[i] = 1 - colors[i];
                        }
                    }
                    return newTexture;
                }
            }

            public static Texture2D GetColors(Texture2D texture, int width, int height, out Color[] Colors,bool unloadTempTexture = false)
            {
                //Thanks to
                //https://gamedev.stackexchange.com/questions/92285/unity3d-resize-texture-without-corruption
                texture.filterMode = FilterMode.Point;
                RenderTexture rt = RenderTexture.GetTemporary(width, height);
                
                rt.filterMode = FilterMode.Point;
                RenderTexture.active = rt;
                Graphics.Blit(texture, rt);
                Texture2D newTexture = new Texture2D(width, height);
                newTexture.ReadPixels(new Rect(0, 0, width, height), 0, 0);
                Color[] myColors = newTexture.GetPixels();
                RenderTexture.active = null;
                /////////////////////
                Colors = myColors;
                if (unloadTempTexture)
                {
                    DestroyImmediate(newTexture);
                    return null;
                }
                return newTexture;
            }
        }
    }
}

// parts for packing textures taken from Dreadrith
// https://github.com/Dreadrith/DreadScripts/tree/main/Texture%20Utility
// MIT License

// Copyright (c) 2020 Dreadrith

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
