using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;
using System.Reflection;

namespace z3y
{
    public partial class LitUIFoldoutDictionary
    {
        public bool AnimatedProps = false;

        public bool ShowSurfaceInputs = true;
        public bool ShowSpecular = false;
        public bool ShowAdvanced = false;
        public bool ShowBakedLight = false;
        public bool ShowShaderFeatures = false;

    }
    
    public class LitUI : ShaderGUI
    {
        protected MaterialProperty _Saturation = null;
        protected MaterialProperty _Color = null;
        protected MaterialProperty _MainTex = null;
        protected MaterialProperty _MetallicGlossMap = null;
        protected MaterialProperty _Metallic = null;
        protected MaterialProperty _Glossiness = null;
        protected MaterialProperty _Occlusion = null;
        protected MaterialProperty _BumpMap = null;
        protected MaterialProperty _BumpScale = null;
        protected MaterialProperty _EmissionMap = null;
        protected MaterialProperty _EnableEmissionBase = null;
        protected MaterialProperty _EmissionColor = null;
        protected MaterialProperty _SpecularHighlights = null;
        protected MaterialProperty _GlossyReflections = null;
        protected MaterialProperty _Reflectance = null;
        protected MaterialProperty _FresnelColor = null;
        protected MaterialProperty _DetailMap = null;
        protected MaterialProperty _DetailAlbedoScale = null;
        protected MaterialProperty _DetailNormalScale = null;
        protected MaterialProperty _DetailSmoothnessScale = null;
        protected MaterialProperty _GSAA = null;
        protected MaterialProperty _specularAntiAliasingVariance = null;
        protected MaterialProperty _specularAntiAliasingThreshold = null;
        protected MaterialProperty _BlendOp = null;
        protected MaterialProperty _BlendOpAlpha = null;
        protected MaterialProperty _SrcBlend = null;
        protected MaterialProperty _DstBlend = null;
        protected MaterialProperty _ZWrite = null;
        protected MaterialProperty _ZTest = null;
        protected MaterialProperty _Cull = null;
        protected MaterialProperty _AlphaToMask = null;
        protected MaterialProperty _Mode = null;
        protected MaterialProperty _Cutoff = null;
        protected MaterialProperty _DetailMapUV = null;




        public void ShaderPropertiesGUI(Material material)
        {

            md[material].ShowSurfaceInputs = Foldout("Surface Inputs", md[material].ShowSurfaceInputs, ()=> {

                EditorGUI.BeginChangeCheck();
                prop(_Mode);
                if (EditorGUI.EndChangeCheck())
                {
                    if(me.targets.Length > 1)
                        foreach(Material m in me.targets)
                        {
                            SetupBlendMode(m, _Mode.floatValue);
                        }
                    else
                        SetupBlendMode(material, _Mode.floatValue);
                }

                if(_Mode.floatValue == 1 || _Mode.floatValue == 5) prop(_Cutoff);
                EditorGUILayout.Space();

                prop(_MainTex, _Color);


                prop(_Saturation);
                prop(_Metallic);
                prop(_Glossiness);

                if (_MetallicGlossMap.textureValue) prop(_Occlusion);

                
                prop(_MetallicGlossMap);
                Func.sRGBWarning(_MetallicGlossMap);

                prop(_BumpMap, _BumpMap.textureValue ? _BumpScale : null);

                prop(_EmissionMap, _EmissionColor);
                EditorGUI.indentLevel++;
                EditorGUI.indentLevel++;
                me.LightmapEmissionProperty();
                prop(_EnableEmissionBase);
                EditorGUI.indentLevel--;
                EditorGUI.indentLevel--;


                propTileOffset(_MainTex);

                EditorGUILayout.Space();
                prop(_DetailMap);
                Func.sRGBWarning(_DetailMap);

                if(_DetailMap.textureValue)
                Func.PropertyGroup(() => {
                    prop(_DetailMapUV);
                    propTileOffset(_DetailMap);
                    prop(_DetailAlbedoScale);
                    prop(_DetailNormalScale);
                    prop(_DetailSmoothnessScale);
                });

            });

            md[material].ShowSpecular = Foldout("Specular Reflections", md[material].ShowSpecular, ()=> {

                prop(_FresnelColor);
                prop(_Reflectance);
                
                EditorGUILayout.Space();
                prop(_GlossyReflections);
                prop(_SpecularHighlights);
            });

            md[material].ShowShaderFeatures = Foldout("Shader Features", md[material].ShowShaderFeatures, ()=> {


                // prop(_EnableParallax);
                // if(_EnableParallax.floatValue == 1)
                // {
                //     Func.PropertyGroup(() => {
                //         prop(_ParallaxMap, _Parallax);
                //         Func.sRGBWarning(_ParallaxMap);
                //         prop(_ParallaxOffset);
                //         prop(_ParallaxSteps);
                //     });
                // }
                

                prop(_GSAA);
                if(_GSAA.floatValue == 1){
                    Func.PropertyGroup(() => {
                        prop(_specularAntiAliasingVariance);
                        prop(_specularAntiAliasingThreshold);
                    });
                };


            });

            md[material].ShowBakedLight = Foldout("Baked Light", md[material].ShowBakedLight, ()=> {

                
                #if BAKERY_INCLUDED
                
                #endif
            });


            md[material].ShowAdvanced = Foldout("Advanced", md[material].ShowAdvanced, ()=> {
                Func.PropertyGroup(() => {
                prop(_BlendOp);
                prop(_BlendOpAlpha);
                prop(_SrcBlend);
                prop(_DstBlend);
                });
                EditorGUILayout.Space();

                prop(_Cull);
                me.DoubleSidedGIField();
                me.EnableInstancingField();
                me.RenderQueueField();
                EditorGUILayout.Space();
            });

            

            


            
        }

        // On inspector change
        private void ApplyChanges(Material material)
        {
            ToggleKeyword(material, _MetallicGlossMap.textureValue, "MASKMAP");
            ToggleKeyword(material, _BumpMap.textureValue, "NORMALMAP");
            if(_EnableEmissionBase.floatValue == 0)
            {
                ToggleKeyword(material, _EmissionMap.textureValue, "EMISSIONMAP");
            } 
            else
            {
                ToggleKeyword(material, false, "EMISSIONMAP");
            }

            if(_DetailMap.textureValue)
            {
                ToggleKeyword(material, _DetailMapUV.floatValue == 0, "DETAILMAP");
                ToggleKeyword(material, _DetailMapUV.floatValue == 1, "DETAILMAP_UV1");
            }
            else
            {
                ToggleKeyword(material, false, "DETAILMAP");
                ToggleKeyword(material, false, "DETAILMAP_UV1");
            }
            

            // Func.SetupGIFlags(emissionEnabled, material);
            

        }

        private void ToggleKeyword(Material material, bool toggle, string keyword)
        {
            if(toggle) material.EnableKeyword(keyword);
            else material.DisableKeyword(keyword);
        }

        protected static Dictionary<Material, LitFoldoutDictionary> md = new Dictionary<Material, LitFoldoutDictionary>();
        protected BindingFlags bindingFlags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static;
        MaterialEditor me;
        public bool m_FirstTimeApply = true;

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
                ApplyChanges(material);
            }
            
            EditorGUI.BeginChangeCheck();
            // EditorGUI.indentLevel++;

            ShaderPropertiesGUI(material);

            if (EditorGUI.EndChangeCheck()) {
                ApplyChanges(material);
            };
        }

        private void prop(MaterialProperty property) => MaterialProp(property, null, null, me);
        private void prop(MaterialProperty property, MaterialProperty extraProperty) => MaterialProp(property, extraProperty, null, me);

        public static void MaterialProp(MaterialProperty property, MaterialProperty extraProperty, MaterialProperty extraProperty2, MaterialEditor me)
        {
 
            if( property.type == MaterialProperty.PropType.Range ||
                property.type == MaterialProperty.PropType.Float ||
                property.type == MaterialProperty.PropType.Vector ||
                property.type == MaterialProperty.PropType.Color)
            {
                me.ShaderProperty(property, property.displayName);
            }

            if(property.type == MaterialProperty.PropType.Texture) 
            {
                string[] p = property.displayName.Split(':');

                me.TexturePropertySingleLine(new GUIContent(p[0], p.Length == 2 ? p[1] : null), property, extraProperty);
            }
        }
        
        private void propTileOffset(MaterialProperty property) => Func.propTileOffset(property, false, me, material);
        private bool Foldout(string foldoutText, bool foldoutName, Action action) => Func.Foldout(foldoutText, foldoutName, action);

        public static void SetupBlendMode(Material material, float type)
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

                    material.DisableKeyword("CUTOUT");
                    material.DisableKeyword("FADE");
                    material.DisableKeyword("TRANSPARENT");
                    material.DisableKeyword("A2C_SHARPENED");
                    break;
                case 1:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    material.SetInt("_AlphaToMask", 0);

                    material.EnableKeyword("CUTOUT");
                    material.DisableKeyword("FADE");
                    material.DisableKeyword("TRANSPARENT");
                    material.DisableKeyword("A2C_SHARPENED");
                    break;
                case 2:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_AlphaToMask", 0);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;

                    material.DisableKeyword("CUTOUT");
                    material.EnableKeyword("FADE");
                    material.DisableKeyword("TRANSPARENT");
                    material.DisableKeyword("A2C_SHARPENED");
                    break;
                case 3:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.SetInt("_AlphaToMask", 0);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;

                    material.DisableKeyword("CUTOUT");
                    material.DisableKeyword("FADE");
                    material.EnableKeyword("TRANSPARENT");
                    material.DisableKeyword("A2C_SHARPENED");
                    break;
                case 4:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    material.SetInt("_AlphaToMask", 1);

                    material.DisableKeyword("CUTOUT");
                    material.DisableKeyword("FADE");
                    material.DisableKeyword("TRANSPARENT");
                    material.DisableKeyword("A2C_SHARPENED");
                    break;
                case 5:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    material.SetInt("_AlphaToMask", 1);

                    material.DisableKeyword("CUTOUT");
                    material.DisableKeyword("FADE");
                    material.DisableKeyword("TRANSPARENT");
                    material.EnableKeyword("A2C_SHARPENED");
                    break;
            }
        }

        

        private void SetupFoldoutDictionary(Material material)
        {
            if (md.ContainsKey(material)) return;

            LitFoldoutDictionary toggles = new LitFoldoutDictionary();
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

    }
}