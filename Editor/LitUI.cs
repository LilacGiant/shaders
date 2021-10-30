using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;
using System.Reflection;

namespace z3y
{
    public partial class LitFoldouts
    {
        public bool AnimatedProps = false;

        public bool ShowSurfaceInputs = true;
        public bool ShowSpecular = false;
        public bool ShowAdvanced = false;
        public bool ShowBakedLight = false;
        public bool ShowShaderFeatures = false;

        public bool Show_MainTex = false;
        public bool Show_MetallicGlossMap = false;
        public bool Show_BumpMap = false;
        public bool Show_EmissionMap = false;
        public bool Show_DetailMap = false;
        public bool Show_AnisotropyMap = false;
        public bool Show_MetallicMap = false;
        public bool Show_SmoothnessMap = false;
        public bool Show_OcclusionMap = false;
        
        public bool Show_RenderingOptions = false;
        public bool Show_ArrayOptions = false;


    }
    
    public class LitUI : ShaderGUI
    {
        protected MaterialProperty _MainTex = null;
        protected MaterialProperty _Color = null;
        protected MaterialProperty _Saturation = null;
        protected MaterialProperty _MainTex_UV = null;
        protected MaterialProperty _Metallic = null;
        protected MaterialProperty _Glossiness = null;
        protected MaterialProperty _Occlusion = null;
        protected MaterialProperty _SpecularHighlights = null;
        protected MaterialProperty _GlossyReflections = null;
        protected MaterialProperty _Reflectance = null;
        protected MaterialProperty _Mode = null;
        protected MaterialProperty _Workflow = null;
        protected MaterialProperty _AlphaToMask = null;
        protected MaterialProperty _Cutoff = null;
        protected MaterialProperty _BicubicLightmap = null;
        protected MaterialProperty _MetallicGlossMap = null;
        protected MaterialProperty _MetallicGlossMap_UV = null;
        protected MaterialProperty _FresnelIntensity = null;
        protected MaterialProperty _SpecularOcclusion = null;
        protected MaterialProperty _BlendOp = null;
        protected MaterialProperty _BlendOpAlpha = null;
        protected MaterialProperty _SrcBlend = null;
        protected MaterialProperty _DstBlend = null;
        protected MaterialProperty _Cull = null;
        protected MaterialProperty _ZWrite = null;
        protected MaterialProperty _ZTest = null;
        protected MaterialProperty _SmoothnessMap = null;
        protected MaterialProperty _SmoothnessMap_UV = null;
        protected MaterialProperty _GlossinessInvert = null;
        protected MaterialProperty _MetallicMap = null;
        protected MaterialProperty _MetallicMap_UV = null;
        protected MaterialProperty _OcclusionMap = null;
        protected MaterialProperty _OcclusionMap_UV = null;
        protected MaterialProperty _BumpMap = null;
        protected MaterialProperty _BumpScale = null;
        protected MaterialProperty _BumpMap_UV = null;
        protected MaterialProperty _NormalMapOrientation = null;
        protected MaterialProperty _HemiOctahedron = null;
        protected MaterialProperty _GSAA = null;
        protected MaterialProperty _specularAntiAliasingVariance = null;
        protected MaterialProperty _specularAntiAliasingThreshold = null;
        protected MaterialProperty _EnableEmission = null;
        protected MaterialProperty _EmissionColor = null;
        protected MaterialProperty _EmissionMap_UV = null;
        protected MaterialProperty _EmissionMultBase = null;
        protected MaterialProperty _EmissionMap = null;
        protected MaterialProperty _DetailMap = null;
        protected MaterialProperty _DetailMap_UV = null;
        protected MaterialProperty _DetailAlbedoScale = null;
        protected MaterialProperty _DetailNormalScale = null;
        protected MaterialProperty _DetailSmoothnessScale = null;
        protected MaterialProperty _EnableParallax = null;
        protected MaterialProperty _Parallax = null;
        protected MaterialProperty _ParallaxOffset = null;
        protected MaterialProperty _ParallaxSteps = null;
        protected MaterialProperty _ParallaxMap = null;
        protected MaterialProperty _NonLinearLightProbeSH = null;
        protected MaterialProperty _BakedSpecular = null;
        protected MaterialProperty _Roughness = null;
        protected MaterialProperty _BAKERY_SH = null;
        protected MaterialProperty _BAKERY_SHNONLINEAR = null;
        protected MaterialProperty _BAKERY_RNM = null;
        protected MaterialProperty bakeryLightmapMode = null;
        protected MaterialProperty _RNM0 = null;
        protected MaterialProperty _RNM1 = null;
        protected MaterialProperty _RNM2 = null;
        protected MaterialProperty _MainTexArray = null;
        protected MaterialProperty _MetallicGlossMapArray = null;
        protected MaterialProperty _TriplanarBlend = null;
        protected MaterialProperty _EnableAnisotropy = null;
        protected MaterialProperty _Anisotropy = null;
        protected MaterialProperty _AnisotropyMap = null;
        protected MaterialProperty _UseTextureIndex = null;
        protected MaterialProperty _BumpMapArray = null;
        protected MaterialProperty _EnableTextureArrayBump = null;
        protected MaterialProperty _FresnelColor = null;
        protected MaterialProperty _EnableTextureArray = null;
        protected MaterialProperty _TextureIndex = null;
        protected MaterialProperty _EnableTextureArrayMask = null;
        protected MaterialProperty _ArrayCount = null;
        protected MaterialProperty _MipScale = null;


        public void ShaderPropertiesGUI(Material material)
        {
            bool texArray = _EnableTextureArray.floatValue == 1;
            
            md[material].ShowSurfaceInputs = Foldout("Surface Inputs", md[material].ShowSurfaceInputs, ()=> {


                EditorGUI.BeginChangeCheck();
                prop(_Mode);
                if (EditorGUI.EndChangeCheck())
                {
                    if(me.targets.Length > 1)
                        foreach(Material m in me.targets)
                        {
                            SetupMaterialWithBlendMode(m, (int)_Mode.floatValue);
                        }
                    else
                        SetupMaterialWithBlendMode(material, (int)_Mode.floatValue);
                }

                int mode = (int)_Mode.floatValue;
                if(mode == 1 || mode == 4){
                    prop(_Cutoff);
                    prop(_MipScale);
                }

                EditorGUILayout.Space();

                
                if(!texArray)
                {
                    prop(_MainTex, _Color);
                }
                else
                {
                    // if(material.enableInstancing) prop(_TextureIndex);
                    prop(_MainTexArray, _Color);
                }
                md[material].Show_MainTex = Func.TriangleFoldout(md[material].Show_MainTex, ()=> {
                    prop(_MainTex_UV);
                    propTileOffset(_MainTex);
                    prop(_Saturation);
                    
                });
                EditorGUILayout.Space();

                switch((int)_Workflow.floatValue)
                {
                    case 0:
                    prop(_Metallic);
                    prop(_Glossiness);
                    prop(_Occlusion);

                    if(_EnableTextureArrayMask.floatValue == 0 || !texArray) prop(_MetallicGlossMap);
                    else prop(_MetallicGlossMapArray);
                    md[material].Show_MetallicGlossMap = Func.TriangleFoldout(md[material].Show_MetallicGlossMap, ()=> {
                        prop(_MetallicGlossMap_UV);
                        if(_MetallicGlossMap_UV.floatValue != 0) propTileOffset(_MetallicGlossMap);
                    });
                    Func.sRGBWarning(_MetallicGlossMap);
                    break;

                    case 1:
                        prop(_MetallicMap, _Metallic);
                        md[material].Show_MetallicMap = Func.TriangleFoldout(md[material].Show_MetallicMap, ()=> {
                            prop(_MetallicMap_UV);
                            if(_MetallicMap_UV.floatValue != 0)  propTileOffset(_MetallicMap);
                        });
                        Func.sRGBWarning(_MetallicMap);
                        
                        prop(_SmoothnessMap, _Glossiness);
                        md[material].Show_SmoothnessMap = Func.TriangleFoldout(md[material].Show_SmoothnessMap, ()=> {
                            prop(_SmoothnessMap_UV);
                            if(_SmoothnessMap_UV.floatValue != 0) propTileOffset(_SmoothnessMap);
                            
                            prop(_GlossinessInvert);
                        });
                        Func.sRGBWarning(_SmoothnessMap);
                        
                        prop(_OcclusionMap, _Occlusion);
                        md[material].Show_OcclusionMap = Func.TriangleFoldout(md[material].Show_OcclusionMap, ()=> {
                            prop(_OcclusionMap_UV);
                            if(_OcclusionMap_UV.floatValue != 0) propTileOffset(_OcclusionMap);
                            
                        });
                        Func.sRGBWarning(_OcclusionMap);
                        break;
                }
                

                if(_EnableTextureArrayBump.floatValue == 0 || !texArray) prop(_BumpMap, _BumpScale);
                else prop(_BumpMapArray, _BumpScale);
                md[material].Show_BumpMap = Func.TriangleFoldout(md[material].Show_BumpMap, ()=> {
                    prop(_BumpMap_UV);
                    if(_BumpMap_UV.floatValue != 0) propTileOffset(_BumpMap);
                    
                    prop(_NormalMapOrientation);
                    prop(_HemiOctahedron);
                });
                

                
                prop(_DetailMap);
                md[material].Show_DetailMap = Func.TriangleFoldout(md[material].Show_DetailMap, ()=> {
                    prop(_DetailMap_UV);
                    if(_DetailMap_UV.floatValue != 0) propTileOffset(_DetailMap);
                    
                    prop(_DetailAlbedoScale);
                    prop(_DetailNormalScale);
                    prop(_DetailSmoothnessScale);
                });

                
                
                if(!texArray)
                {
                    prop(_EnableParallax);
                    if(_EnableParallax.floatValue == 1)
                    {
                        Func.PropertyGroup(() => {
                            prop(_ParallaxMap, _Parallax);
                            prop(_ParallaxOffset);
                            prop(_ParallaxSteps);
                        });
                    }
                    Func.sRGBWarning(_ParallaxMap);
                }


                prop(_EnableEmission);
                if(_EnableEmission.floatValue == 1)
                {
                    Func.PropertyGroup(() => {
                        prop(_EmissionMap, _EmissionColor);

                        md[material].Show_EmissionMap = Func.TriangleFoldout(md[material].Show_EmissionMap, ()=> {
                            prop(_EmissionMap_UV);
                            if(_EmissionMap_UV.floatValue != 0) propTileOffset(_EmissionMap);
                            
                        });
                        me.LightmapEmissionProperty();
                        prop(_EmissionMultBase);
                    });
                }
                


            });

            md[material].ShowSpecular = Foldout("Specular Reflections", md[material].ShowSpecular, ()=> {
                prop(_GlossyReflections);
                prop(_SpecularHighlights);
                prop(_Reflectance);
                prop(_FresnelIntensity);
                prop(_SpecularOcclusion);
                prop(_FresnelColor);

                
                prop(_GSAA);
                if(_GSAA.floatValue == 1){
                    Func.PropertyGroup(() => {
                        prop(_specularAntiAliasingVariance);
                        prop(_specularAntiAliasingThreshold);
                    });
                };

                prop(_EnableAnisotropy);
                
                if(_EnableAnisotropy.floatValue == 1){
                    Func.PropertyGroup(() => {
                        prop(_Anisotropy);
                        prop(_AnisotropyMap);
                        propTileOffset(_AnisotropyMap);
                    });
                };
            });

            md[material].ShowShaderFeatures = Foldout("Shader Features", md[material].ShowShaderFeatures, ()=> {

                
                

            });

            md[material].ShowBakedLight = Foldout("Indirect Diffuse", md[material].ShowBakedLight, ()=> {
                prop(_BicubicLightmap);
                prop(_NonLinearLightProbeSH);
                prop(_BakedSpecular);

                // #if BAKERY_INCLUDED
                // Func.PropertyGroup(() => {
                //     EditorGUILayout.LabelField("Bakery", EditorStyles.boldLabel);
                //     prop(_BAKERY_SH);
                //     prop(_BAKERY_SHNONLINEAR);
                //     prop(_BAKERY_RNM);
                //     EditorGUI.BeginDisabledGroup(true);
                //     if(_BAKERY_SH.floatValue == 1 || _BAKERY_RNM.floatValue == 1)
                //     {
                //         prop(bakeryLightmapMode);
                //         prop(_RNM0);
                //         prop(_RNM1);
                //         prop(_RNM2);
                //     }
                //     EditorGUI.EndDisabledGroup();
                // });
                // #endif
            });


            md[material].ShowAdvanced = Foldout("Advanced", md[material].ShowAdvanced, ()=> {

                EditorGUILayout.LabelField("Rendering Options", EditorStyles.boldLabel);
                md[material].Show_RenderingOptions = Func.TriangleFoldout(md[material].Show_RenderingOptions, ()=> {
                    prop(_BlendOp);
                    prop(_BlendOpAlpha);
                    prop(_SrcBlend);
                    prop(_DstBlend);
                    prop(_ZWrite);
                    prop(_ZTest);
                    prop(_AlphaToMask);
                });
                EditorGUILayout.Space();

                prop(_EnableTextureArray);
                if(texArray)
                {                    
                    prop(_EnableTextureArrayMask);
                    prop(_EnableTextureArrayBump);
                }

                prop(_Workflow);
                
                me.DoubleSidedGIField();
                me.EnableInstancingField();
                me.RenderQueueField();
                prop(_Cull);

                EditorGUILayout.Space();
                ListAnimatedProps();
            });

            

            


            
        }

        // On inspector change
        private void ApplyChanges()
        {
            Func.SetupGIFlags(_EnableEmission.floatValue, material);

            if(wAg6H2wQzc7UbxaL.floatValue != 0) return;
        }

        protected static Dictionary<Material, LitFoldouts> md = new Dictionary<Material, LitFoldouts>();
        protected BindingFlags bindingFlags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static;
        MaterialEditor me;
        public bool m_FirstTimeApply = true;
        protected MaterialProperty wAg6H2wQzc7UbxaL = null;

        public bool isLocked;
        Material material = null;
        MaterialProperty[] allProps;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            FindProperties(props);
            me = materialEditor;
            material = materialEditor.target as Material;
            SetupFoldoutDictionary(material);
            allProps = props;

            if (m_FirstTimeApply)
            {
                m_FirstTimeApply = false;
            }
            
            Func.ShaderOptimizerButton(wAg6H2wQzc7UbxaL, me);
            isLocked = wAg6H2wQzc7UbxaL.floatValue == 1;
            EditorGUI.BeginChangeCheck();
            EditorGUI.indentLevel++;

            ShaderPropertiesGUI(material);

            if (EditorGUI.EndChangeCheck()) {
                ApplyChanges();
            };
        }

        private void prop(MaterialProperty property) => Func.MaterialProp(property, null, me, isLocked, material, null);
        private void prop(MaterialProperty property, MaterialProperty extraProperty) => Func.MaterialProp(property, extraProperty, me, isLocked, material, null);
        private void prop(MaterialProperty property, MaterialProperty extraProperty, string nameOverride) => Func.MaterialProp(property, extraProperty, me, isLocked, material, nameOverride);
        
        private void propTileOffset(MaterialProperty property) => Func.propTileOffset(property, isLocked, me, material);
        private void ListAnimatedProps() => Func.ListAnimatedProps(isLocked, allProps, material);
        private bool Foldout(string foldoutText, bool foldoutName, Action action) => Func.Foldout(foldoutText, foldoutName, action);

        

        private void SetupFoldoutDictionary(Material material)
        {
            if (md.ContainsKey(material)) return;

            LitFoldouts toggles = new LitFoldouts();
            md.Add(material, toggles);
        }
        
        public void FindProperties(MaterialProperty[] props)
        {
            //Find all material properties listed in the script using reflection, and set them using a loop only if they're of type MaterialProperty.
            //This makes things a lot nicer to maintain and cleaner to look at.
            foreach (var property in GetType().GetFields(bindingFlags))
            {
                if (property.FieldType == typeof(MaterialProperty))
                {
                    try { property.SetValue(this, FindProperty(property.Name, props)); } catch { /*Is it really a problem if it doesn't exist?*/ }
                }
            }
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