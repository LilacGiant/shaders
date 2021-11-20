using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;
using z3y.ShaderEditorFunctions;
using static z3y.ShaderEditorFunctions.Functions;

namespace z3y.ShaderEditor
{

    public class LitUI : ShaderGUI
    {

        public void ShaderPropertiesGUI(Material material, MaterialProperty[] props, MaterialEditor materialEditor)
        {
            if(!isLocked)
            {
                if(isBakeryMaterial)
                {
                    EditorGUI.indentLevel--;
                    EditorGUILayout.HelpBox("Revert Bakery materials before editing: Tools > Shader Optimizer > Revert Bakery Materials", MessageType.Info);
                    EditorGUI.indentLevel++;
                    isLocked = true;
                }
            }

            DrawFoldout("Surface Inputs", ()=>
            {

                EditorGUI.BeginChangeCheck();
                Prop("_Mode");
                if (EditorGUI.EndChangeCheck())
                {
                    foreach(Material m in materialEditor.targets)
                    {
                        SetupMaterialWithBlendMode(m, (int)GetProperty("_Mode").floatValue);
                    }
                }

                if(GetFloatValue("_Mode") == 1) Prop("_Cutoff");

                EditorGUILayout.Space();

                Prop(IfProp("_EnableTextureArray") ? "_MainTexArray" : "_MainTex", "_Color");
                DrawTriangleFoldout("_MainTex", ()=>
                {
                    Prop("_MainTex_UV");
                    PropTileOffset("_MainTex");
                    Prop("_Saturation");
                });
                EditorGUILayout.Space();

                

                if (!IfProp("_Workflow"))
                {
                    if(IfProp("_EnableTextureArray") ? GetProperty("_MetallicGlossMapArray").textureValue is null : GetProperty("_MetallicGlossMap").textureValue is null)
                    {
                        Prop("_Metallic");
                        Prop("_Glossiness");
                    }
                    else
                    {
                        RangedProp(GetProperty("_GlossinessMin"), GetProperty("_Glossiness"));
                        RangedProp(GetProperty("_MetallicMin"), GetProperty("_Metallic"));
                        RangedProp(GetProperty("_OcclusionMin"), GetProperty("_Occlusion"));
                    }
                    
                    Prop(IfProp("_EnableTextureArray") && IfProp("_EnableTextureArray") ? "_MetallicGlossMapArray" : "_MetallicGlossMap");
                    DrawTriangleFoldout("_MetallicGlossMap", ()=>
                    {
                        Prop("_MetallicGlossMap_UV");
                        if (GetFloatValue("_MetallicGlossMap_UV") != 0) PropTileOffset("_MetallicGlossMap");
                    });
                    sRGBWarning(GetProperty("_MetallicGlossMap"));
                }
                else
                {
                    if(GetProperty("_MetallicMap").textureValue is null)
                        Prop("_MetallicMap", "_Metallic");
                    else
                        RangedProp(GetProperty("_MetallicMin"), GetProperty("_Metallic"), 0, 1, GetProperty("_MetallicMap"));
                    DrawTriangleFoldout("_MetallicMap", ()=>
                    {

                        Prop("_MetallicMap_UV");
                        if (GetFloatValue("_MetallicMap_UV") != 0) PropTileOffset("_MetallicMap");
                    });
                    sRGBWarning(GetProperty("_MetallicMap"));

                    if(GetProperty("_SmoothnessMap").textureValue is null)
                        Prop("_SmoothnessMap", "_Glossiness");
                    else
                        RangedProp(GetProperty("_GlossinessMin"), GetProperty("_Glossiness"), 0, 1, GetProperty("_SmoothnessMap"));
                    DrawTriangleFoldout("_SmoothnessMap", ()=>
                    {
                        Prop("_SmoothnessMap_UV");
                        if (GetFloatValue("_SmoothnessMap_UV") != 0) PropTileOffset("_SmoothnessMap");

                        Prop("_GlossinessInvert");
                    });
                    sRGBWarning(GetProperty("_SmoothnessMap"));

                    if(GetProperty("_OcclusionMap").textureValue is null)
                        Prop("_OcclusionMap", "_Occlusion");
                    else
                        RangedProp(GetProperty("_OcclusionMin"), GetProperty("_Occlusion"), 0, 1, GetProperty("_OcclusionMap"));
                    DrawTriangleFoldout("_OcclusionMap", ()=>
                    {
                        Prop("_OcclusionMap_UV");
                        if (GetFloatValue("_OcclusionMap_UV") != 0) PropTileOffset("_OcclusionMap");
                    });
                    sRGBWarning(GetProperty("_OcclusionMap"));
                }


                if(!IfProp("_EnableTextureArray") || !IfProp("_EnableTextureArray")) Prop("_BumpMap", "_BumpScale");
                else Prop("_BumpMapArray", "_BumpScale");
                DrawTriangleFoldout("_BumpMap", ()=>
                {
                    Prop("_BumpMap_UV");
                    if(GetFloatValue("_BumpMap_UV") != 0) PropTileOffset("_BumpMap");
                    
                    Prop("_NormalMapOrientation");
                    Prop("_HemiOctahedron");
                });
                

                
                

                
                
                Prop("_EnableEmission");
                if(IfProp("_EnableEmission"))
                {
                    PropertyGroup(() => {
                        Prop("_EmissionMap", "_EmissionColor");
                        
                        DrawTriangleFoldout("_EmissionMap", ()=>
                        {
                            Prop("_EmissionMap_UV");
                            if(GetProperty("_EmissionMap_UV").floatValue != 0) PropTileOffset("_EmissionMap");
                            
                        });
                        materialEditor.LightmapEmissionProperty();
                        Prop("_EmissionMultBase");

                        if(IfProp("_EnableAudioLink"))
                        {
                            EditorGUILayout.Space();
                            Prop("_ALEmissionType");
                            if(GetProperty("_ALEmissionType").floatValue != 0){
                                Prop("_ALEmissionBand");
                                Prop("_ALEmissionMap");
                                sRGBWarning(GetProperty("_ALEmissionMap"));
                            }
                        }
                    });
                }
                
                if(!IfProp("_EnableTextureArray"))
                {
                    Prop("_EnableParallax");
                    if(IfProp("_EnableParallax"))
                    {
                        PropertyGroup(() => {
                            Prop("_ParallaxMap", "_Parallax");
                            Prop("_ParallaxOffset");
                            Prop("_ParallaxSteps");
                        });
                    }
                    sRGBWarning(GetProperty("_ParallaxMap"));
                }


                
                


            }, true);

            DrawFoldout("Details", ()=>
            {

            Prop("_DetailPacked");
            if(IfProp("_DetailPacked"))
            {
                Prop("_DetailMap");
            }
            else
            {
                Prop("_DetailAlbedoMap");
                Prop("_DetailMaskMap");
                sRGBWarning(GetProperty("_DetailMaskMap"));

                Prop("_DetailNormalMap");
            }
            EditorGUILayout.Space();

            Prop("_DetailAlbedoScale");
            Prop("_DetailNormalScale");
            Prop("_DetailSmoothnessScale");

            EditorGUILayout.Space();

            Prop("_DetailMaskScale");
            Prop("_DetailMap_UV");
            PropTileOffset("_DetailMap");
                

            });
            
            DrawFoldout("Specular", ()=>
            {

                Prop("_GlossyReflections");
                Prop("_SpecularHighlights");
                EditorGUILayout.Space();

                Prop("_Reflectance");
                Prop("_FresnelIntensity");
                Prop("_SpecularOcclusion");
                Prop("_FresnelColor");
                EditorGUILayout.Space();

            
                Prop("_GSAA");
                if(IfProp("_GSAA"))
                {
                    PropertyGroup(() => {
                        Prop("_specularAntiAliasingVariance");
                        Prop("_specularAntiAliasingThreshold");
                        Prop("_GSAANormal");
                    });
                };

                Prop("_EnableAnisotropy");
                
                if(IfProp("_EnableAnisotropy"))
                {
                    PropertyGroup(() => 
                    {
                        Prop("_Anisotropy");
                        Prop("_AnisotropyMap");
                        PropTileOffset("_AnisotropyMap");
                    });
                };
            });
            
            DrawFoldout("Lighting", ()=>
            {
                Prop("_BicubicLightmap");
                Prop("_NonLinearLightProbeSH");
                Prop("_BakedSpecular");

                #if BAKERY_INCLUDED
                PropertyGroup(() => {
                    EditorGUILayout.LabelField("Bakery", EditorStyles.boldLabel);
                    Prop("_BAKERY_SH");
                    Prop("_BAKERY_SHNONLINEAR");
                    Prop("_BAKERY_RNM");
                    if(IfProp("_BAKERY_SH") || IfProp("_BAKERY_RNM"))
                    {
                        EditorGUI.BeginDisabledGroup(true);
                        Prop("bakeryLightmapMode");
                        Prop("_RNM0");
                        Prop("_RNM1");
                        Prop("_RNM2");
                        EditorGUI.EndDisabledGroup();
                    EditorGUI.indentLevel--;
                    EditorGUILayout.HelpBox("Generate Bakery materials before locking: Toos > Shader Optimizer > Generate Bakery Materials", MessageType.Info);
                    EditorGUI.indentLevel++;
                    }
                });
                #endif
            });
            
            DrawFoldout("Advanced", ()=>
            {
                EditorGUILayout.LabelField("Rendering Options", EditorStyles.boldLabel);
                DrawTriangleFoldout("Rendering Options", () => 
                {
                    Prop("_BlendOp");
                    Prop("_BlendOpAlpha");
                    Prop("_SrcBlend");
                    Prop("_DstBlend");
                    Prop("_ZWrite");
                    Prop("_ZTest");
                    Prop("_AlphaToMask");
                });
                EditorGUILayout.Space();

                Prop("_EnableTextureArray");
                if(IfProp("_EnableTextureArray"))
                {                    
                    Prop("_EnableTextureArrayInstancing");
                }
                EditorGUILayout.Space();

                Prop("_Workflow");
                Prop("VertexLights");
                Prop("_LodCrossFade");
                EditorGUILayout.Space();
                


                Prop("_EnableAudioLink");
                if(IfProp("_EnableAudioLink"))
                {
                    PropertyGroup(() =>
                    {
                        Prop("_AudioTexture");
                        Prop("_ALSmoothing");
                    });
                };
                Prop("_EnableStochastic");
                if(IfProp("_EnableStochastic"))
                {
                    PropTileOffset("_Stochastic");
                }
                
                EditorGUILayout.Space();
                
                materialEditor.DoubleSidedGIField();
                materialEditor.EnableInstancingField();
                materialEditor.RenderQueueField();
                Prop("_Cull");
                EditorGUILayout.Space();
                DrawAnimatedPropertiesList(isLocked, props, material);
            });
            
        }

        // On inspector change
        private void ApplyChanges(MaterialProperty[] props)
        {
            SetupGIFlags(GetProperty("_EnableEmission").floatValue, material);
            
            if(GetProperty("wAg6H2wQzc7UbxaL").floatValue != 0) return;
        }

        MaterialEditor materialEditor;
        public bool m_FirstTimeApply = true;

        public bool isLocked;
        public bool isBakeryMaterial;
        Material material = null;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            this.materialEditor = materialEditor;
            material = materialEditor.target as Material;

            if (m_FirstTimeApply)
            {
                m_FirstTimeApply = false;
                SetupFoldoutDictionary(material);
                SetupPropertiesDictionary(props);
                isBakeryMaterial = !material.GetTag("OriginalMaterialPath", false, string.Empty).Equals(string.Empty, StringComparison.Ordinal);
            }
            SetupPropertiesDictionary(props);
            
            if(GetProperty("wAg6H2wQzc7UbxaL") != null)
            {
                ShaderOptimizerButton(GetProperty("wAg6H2wQzc7UbxaL"), materialEditor);
                isLocked = GetFloatValue("wAg6H2wQzc7UbxaL") == 1;
                EditorGUI.indentLevel++;
            }
            EditorGUI.BeginChangeCheck();

            ShaderPropertiesGUI(material, props, materialEditor);

            if (EditorGUI.EndChangeCheck()) {
                ApplyChanges(props);
            };
        }

        public static void SetupMaterialWithBlendMode(Material material, int type)
        {
            switch (type)
            {
                case 0:
                    material.SetOverrideTag("RenderType", "");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.SetInt("_AlphaToMask", 0);
                    material.renderQueue = -1;
                    break;
                case 1:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    material.SetInt("_AlphaToMask", 1);
                    break;
                case 2:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    material.SetInt("_AlphaToMask", 0);
                    break;
                case 3:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    material.SetInt("_AlphaToMask", 0);
                    break;
            }
        }


        // inspector setup
        protected static Dictionary<Material, InspectorData> data = new Dictionary<Material, InspectorData>();

        private void Prop(string property, string extraProperty = null) => MaterialProp(GetProperty(property), extraProperty is null ? null : GetProperty(extraProperty), materialEditor, isLocked, material);
        private void PropTileOffset(string property) => DrawPropTileOffset(GetProperty(property), isLocked, materialEditor, material);
        public float GetFloatValue(string name) => (float)GetProperty(name)?.floatValue;
        public bool IfProp(string name) => GetProperty(name)?.floatValue == 1;

        private void RangedProp(MaterialProperty min, MaterialProperty max, float minLimit = 0, float maxLimit = 1, MaterialProperty tex = null)
        {
            float currentMin = min.floatValue;
            float currentMax = max.floatValue;
            EditorGUI.BeginDisabledGroup(isLocked);
            EditorGUILayout.BeginHorizontal();

            if(tex is null)
                EditorGUILayout.LabelField(max.displayName);
            else
                materialEditor.TexturePropertySingleLine(new GUIContent(tex.displayName), tex);


            EditorGUI.indentLevel -= 5;
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.MinMaxSlider(ref currentMin,ref currentMax, minLimit, maxLimit);
            if(EditorGUI.EndChangeCheck())
            {
                min.floatValue = currentMin;
                max.floatValue = currentMax;
            }
            EditorGUI.indentLevel += 5;
            EditorGUILayout.EndHorizontal();
            EditorGUI.EndDisabledGroup();
            HandleMouseEvents(max, material, min);
        }


        private void SetupPropertiesDictionary(MaterialProperty[] props)
        {
            data[material].MaterialProperties.Clear();
            for (int i = 0; i < props.Length; i++)
            {
                MaterialProperty p = props[i];
                data[material].MaterialProperties[p.name] = p;
            }
        }

        private MaterialProperty GetProperty(string name)
        {
            data[material].MaterialProperties.TryGetValue(name, out MaterialProperty p);
            return p;
        }

        public void DrawFoldout(string name, Action action, bool defaultValue = false)
        {
            data[material].FoldoutValues.TryGetValue(name, out bool? isOpen);
            bool o = isOpen ?? defaultValue;
            o = Foldout(name, o, action);
            data[material].FoldoutValues[name] = o;
        }
        
        public void DrawTriangleFoldout(string name, Action action, bool defaultValue = false)
        {
            data[material].FoldoutValues.TryGetValue(name, out bool? isOpen);
            bool o = isOpen ?? defaultValue;
            o = TriangleFoldout(o, action);
            data[material].FoldoutValues[name] = o;
        }

        private void SetupFoldoutDictionary(Material material)
        {
            if (data.ContainsKey(material)) return;

            InspectorData toggles = new InspectorData();
            data.Add(material, toggles);
        }
    }
}