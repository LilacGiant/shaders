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

        public void ShaderPropertiesGUI(Material material)
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
                    foreach(Material m in me.targets)
                    {
                        SetupMaterialWithBlendMode(m, (int)GetProperty("_Mode").floatValue);
                    }
                }

                int mode = (int)GetProperty("_Mode").floatValue;
                if(mode == 1 || mode == 4)
                {
                    Prop("_Cutoff");
                    Prop("_MipScale");
                }
                EditorGUILayout.Space();

                Prop(IfProp("_EnableTextureArray") ? "_MainTexArray" : "_MainTex", "_Color");
                DrawTriangleFoldout("_MainTex", ()=>
                {
                    Prop("_MainTex_UV");
                    propTileOffset("_MainTex");
                    Prop("_Saturation");
                });
                EditorGUILayout.Space();

                if (!IfProp("_Workflow"))
                {
                    Prop("_Metallic");
                    Prop("_Glossiness");
                    Prop("_Occlusion");
                    
                    Prop(IfProp("_EnableTextureArrayMask") && IfProp("_EnableTextureArray") ? "_MetallicGlossMapArray" : "_MetallicGlossMap");
                    DrawTriangleFoldout("_MetallicGlossMap", ()=>
                    {
                        Prop("_MetallicGlossMap_UV");
                        if (GetProperty("_MetallicGlossMap_UV").floatValue != 0) propTileOffset("_MetallicGlossMap");
                    });
                    sRGBWarning(GetProperty("_MetallicGlossMap"));
                }
                else
                {
                    Prop("_MetallicMap", "_Metallic");
                    DrawTriangleFoldout("_MetallicMap", ()=>
                    {

                        Prop("_MetallicMap_UV");
                        if (GetProperty("_MetallicMap_UV").floatValue != 0) propTileOffset("_MetallicMap");
                    });
                    sRGBWarning(GetProperty("_MetallicMap_"));

                    Prop("_SmoothnessMap", "_Glossiness");
                    DrawTriangleFoldout("_SmoothnessMap", ()=>
                    {
                        Prop("_SmoothnessMap_UV");
                        if (GetProperty("_SmoothnessMap_UV").floatValue != 0) propTileOffset("_SmoothnessMap");

                        Prop("_GlossinessInvert");
                    });
                    sRGBWarning(GetProperty("_SmoothnessMap_"));

                    Prop("_OcclusionMap", "_Occlusion");
                    DrawTriangleFoldout("_OcclusionMap", ()=>
                    {
                        Prop("_OcclusionMap_UV");
                        if (GetProperty("_OcclusionMap_UV").floatValue != 0) propTileOffset("_OcclusionMap");
                    });
                    sRGBWarning(GetProperty("_OcclusionMap"));
                }


                if(!IfProp("_EnableTextureArrayBump") || !IfProp("_EnableTextureArray")) Prop("_BumpMap", "_BumpScale");
                else Prop("_BumpMapArray", "_BumpScale");
                DrawTriangleFoldout("_BumpMap", ()=>
                {
                    Prop("_BumpMap_UV");
                    if(GetProperty("_BumpMap_UV").floatValue != 0) propTileOffset("_BumpMap");
                    
                    Prop("_NormalMapOrientation");
                    Prop("_HemiOctahedron");
                });
                

                
                Prop("_DetailMap");
                DrawTriangleFoldout("_DetailMap", ()=>
                {
                    Prop("_DetailMap_UV");
                    if(GetProperty("_DetailMap_UV").floatValue != 0) propTileOffset("_DetailMap");
                    
                    Prop("_DetailAlbedoScale");
                    Prop("_DetailNormalScale");
                    Prop("_DetailSmoothnessScale");
                });

                
                
                Prop("_EnableEmission");
                if(IfProp("_EnableEmission"))
                {
                    PropertyGroup(() => {
                        Prop("_EmissionMap", "_EmissionColor");
                        
                        DrawTriangleFoldout("_EmissionMap", ()=>
                        {
                            Prop("_EmissionMap_UV");
                            if(GetProperty("_EmissionMap_UV").floatValue != 0) propTileOffset("_EmissionMap");
                            
                        });
                        me.LightmapEmissionProperty();
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
                    });
                };

                Prop("_EnableAnisotropy");
                
                if(IfProp("_EnableAnisotropy"))
                {
                    PropertyGroup(() => 
                    {
                        Prop("_Anisotropy");
                        Prop("_AnisotropyMap");
                        propTileOffset("_AnisotropyMap");
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
                    Prop("_EnableTextureArrayMask");
                    Prop("_EnableTextureArrayBump");
                }
                EditorGUILayout.Space();

                Prop("_Workflow");
                Prop("VertexLights");
                Prop("_LodCrossFade");
                // prop(_EnableStochastic);
                // if(_EnableStochastic.floatValue == 1)
                // {
                //     propTileOffset(_Stochastic);
                // }


                Prop("_EnableAudioLink");
                if(IfProp("_EnableAudioLink"))
                {
                    PropertyGroup(() =>
                    {
                        Prop("_AudioTexture");
                        Prop("_ALSmoothing");
                    });
                };
                
                EditorGUILayout.Space();
                
                me.DoubleSidedGIField();
                me.EnableInstancingField();
                me.RenderQueueField();
                Prop("_Cull");
                EditorGUILayout.Space();
                DrawAnimatedPropertiesList(isLocked, allProps, material);
            });

            

            


            
        }

        // On inspector change
        private void ApplyChanges()
        {
            SetupGIFlags(GetProperty("_EnableEmission").floatValue, material);
            
            if(GetProperty("wAg6H2wQzc7UbxaL").floatValue != 0) return;
        }

        protected static Dictionary<Material, InspectorData> data = new Dictionary<Material, InspectorData>();
        MaterialEditor me;
        public bool m_FirstTimeApply = true;

        public bool isLocked;
        public bool isBakeryMaterial;
        Material material = null;
        MaterialProperty[] allProps;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            me = materialEditor;
            material = materialEditor.target as Material;
            allProps = props;

            if (m_FirstTimeApply)
            {
                m_FirstTimeApply = false;
                SetupFoldoutDictionary(material);
                SetupPropertiesDictionary(props);
                isBakeryMaterial = !material.GetTag("OriginalMaterialPath", false, string.Empty).Equals(string.Empty, StringComparison.Ordinal);

            }
            
            if(GetProperty("wAg6H2wQzc7UbxaL") != null)
            {
                ShaderOptimizerButton(GetProperty("wAg6H2wQzc7UbxaL"), me);
                isLocked = GetProperty("wAg6H2wQzc7UbxaL").floatValue == 1;
                EditorGUI.indentLevel++;
            }
            EditorGUI.BeginChangeCheck();

            ShaderPropertiesGUI(material);

            if (EditorGUI.EndChangeCheck()) {
                ApplyChanges();
            };
        }


        // public static Dictionary<string, MaterialProperty> MaterialProperties = new Dictionary<string, MaterialProperty>();
        private void SetupPropertiesDictionary(MaterialProperty[] props)
        {
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

        
        
        private void Prop(string property, string extraProperty = null) => MaterialProp(GetProperty(property), extraProperty is null ? null : GetProperty(extraProperty), me, isLocked, material);


        private void propTileOffset(string property) => DrawPropTileOffset(GetProperty(property), isLocked, me, material);

        public void DrawFoldout(string name, Action action, bool defaultValue = false)
        {
            data[material].values.TryGetValue(name, out bool? isOpen);
            bool o = isOpen ?? defaultValue;
            o = Foldout(name, o, action);
            data[material].values[name] = o;
        }
        
        
        public void DrawTriangleFoldout(string name, Action action, bool defaultValue = false)
        {
            data[material].values.TryGetValue(name, out bool? isOpen);
            bool o = isOpen ?? defaultValue;
            o = TriangleFoldout(o, action);
            data[material].values[name] = o;
        }

        public bool IfProp(string name) => GetProperty(name)?.floatValue == 1;

        public int PropEnumValue(string name) => (int)GetProperty(name)?.floatValue;


        private void SetupFoldoutDictionary(Material material)
        {
            if (data.ContainsKey(material)) return;

            InspectorData toggles = new InspectorData();
            data.Add(material, toggles);
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


    }
}