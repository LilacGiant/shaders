using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;
using System.Reflection;

namespace z3y
{
    public partial class LitFoldoutDictionary
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

        public bool Show_MetallicMap = false;
        public bool Show_SmoothnessMap = false;
        public bool Show_OcclusionMap = false;

    }
    
    public class LitShaderEditor : ShaderGUI
    {
        protected MaterialProperty _MainTex = null;
        protected MaterialProperty _Color = null;
        protected MaterialProperty _Saturation = null;
        protected MaterialProperty _MainTexUV = null;
        protected MaterialProperty _Metallic = null;
        protected MaterialProperty _Glossiness = null;
        protected MaterialProperty _Occlusion = null;
        protected MaterialProperty _MetallicGlossMap = null;
        protected MaterialProperty _MetallicGlossMapUV = null;
        protected MaterialProperty _BumpMap = null;
        protected MaterialProperty _BumpScale = null;
        protected MaterialProperty _BumpMapUV = null;
        protected MaterialProperty _NormalMapOrientation = null;
        protected MaterialProperty _EmissionMap = null;
        protected MaterialProperty _EmissionColor = null;
        protected MaterialProperty _EmissionMapUV = null;
        protected MaterialProperty _EnableEmission = null;
        protected MaterialProperty _EnableNormalMap = null;
        protected MaterialProperty _SpecularHighlights = null;
        protected MaterialProperty _GlossyReflections = null;
        protected MaterialProperty _Reflectance = null;
        protected MaterialProperty _GetDominantLight = null;
        protected MaterialProperty _Mode = null;
        protected MaterialProperty _AlphaToMask = null;
        protected MaterialProperty _Cutoff = null;
        protected MaterialProperty _GSAA = null;
        protected MaterialProperty _specularAntiAliasingVariance = null;
        protected MaterialProperty _specularAntiAliasingThreshold = null;
        protected MaterialProperty _FresnelColor = null;
        protected MaterialProperty _BicubicLightmap = null;
        protected MaterialProperty _LightmapMultiplier = null;
        protected MaterialProperty _SpecularOcclusion = null;
        protected MaterialProperty _LightProbeMethod = null;
        protected MaterialProperty _Anisotropy = null;
        protected MaterialProperty _Cull = null;

        protected MaterialProperty _EnablePackedMode = null;
        protected MaterialProperty _SmoothnessMap = null;
        protected MaterialProperty _SmoothnessMapUV = null;
        protected MaterialProperty _GlossinessInvert = null;
        protected MaterialProperty _MetallicMap = null;
        protected MaterialProperty _MetallicMapUV = null;
        protected MaterialProperty _OcclusionMap = null;
        protected MaterialProperty _OcclusionMapUV = null;

        protected MaterialProperty _EnableParallax = null;
        protected MaterialProperty _Parallax = null;
        protected MaterialProperty _ParallaxMap = null;
        protected MaterialProperty _ParallaxSteps = null;
        protected MaterialProperty _ParallaxOffset = null;

        protected MaterialProperty _DetailMap = null;
        protected MaterialProperty _DetailMapUV = null;
        protected MaterialProperty _DetailAlbedoScale = null;
        protected MaterialProperty _DetailNormalScale = null;
        protected MaterialProperty _DetailSmoothnessScale = null;

        protected MaterialProperty _EnableRefraction = null;
        protected MaterialProperty _Refraction = null;

        protected MaterialProperty _EnableAudioLink = null;
        protected MaterialProperty _ALSmoothing = null;
        protected MaterialProperty _AudioTexture = null;

        protected MaterialProperty _ALEmissionBand = null;
        protected MaterialProperty _ALEmissionType = null;
        protected MaterialProperty _ALEmissionMap = null;
        
        protected MaterialProperty _BAKERY_SH = null;
        protected MaterialProperty _BAKERY_SHNONLINEAR = null;
        protected MaterialProperty _BAKERY_RNM = null;
        protected MaterialProperty _BAKERY_LMSPEC = null;

        protected MaterialProperty bakeryLightmapMode = null;
        protected MaterialProperty _RNM0 = null;
        protected MaterialProperty _RNM1 = null;
        protected MaterialProperty _RNM2 = null;

        protected MaterialProperty _LodCrossFade = null;
        protected MaterialProperty _FlatShading = null;




        public void ShaderPropertiesGUI(Material material)
        {
            #if UNITY_ANDROID && (VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3)
            EditorGUILayout.HelpBox("This shader is not supported on Quest", MessageType.Warning);
            EditorGUILayout.Space();
            #endif

            md[material].ShowSurfaceInputs = Foldout("Surface Inputs", md[material].ShowSurfaceInputs, ()=> {

                EditorGUI.BeginChangeCheck();
                prop(_Mode, false);
                if (EditorGUI.EndChangeCheck()) Func.SetupMaterialWithBlendMode(material, _Mode);

                if(_Mode.floatValue == 1){
                    prop(_AlphaToMask);
                    prop(_Cutoff);
                }
                EditorGUILayout.Space();;

                prop(_MainTex, _Color);

                md[material].Show_MainTex = Func.TriangleFoldout(md[material].Show_MainTex, ()=> {
                    propTileOffset(_MainTex);
                    prop(_MainTexUV, false);
                    prop(_Saturation);
                });

            
                if(_EnablePackedMode.floatValue == 1)
                {
                    prop(_Metallic);
                    prop(_Glossiness);

                    if (_MetallicGlossMap.textureValue || _EnablePackedMode.floatValue == 0) prop(_Occlusion);

                
                    prop(_MetallicGlossMap);
                    md[material].Show_MetallicGlossMap = Func.TriangleFoldout(md[material].Show_MetallicGlossMap, ()=> {
                        propTileOffset(_MetallicGlossMap);
                        prop(_MetallicGlossMapUV, false);
                    });
                    Func.sRGBWarning(_MetallicGlossMap);
                }
                else
                {
                    prop(_MetallicMap, _Metallic);
                    md[material].Show_MetallicMap = Func.TriangleFoldout(md[material].Show_MetallicMap, ()=> {
                        propTileOffset(_MetallicMap);
                        prop(_MetallicMapUV, false);
                    });
                    Func.sRGBWarning(_MetallicMap);
                    
                    prop(_SmoothnessMap, _Glossiness);
                    md[material].Show_SmoothnessMap = Func.TriangleFoldout(md[material].Show_SmoothnessMap, ()=> {
                        propTileOffset(_SmoothnessMap);
                        prop(_SmoothnessMapUV, false);
                        prop(_GlossinessInvert, false);
                    });
                    Func.sRGBWarning(_SmoothnessMap);
                    
                    prop(_OcclusionMap, _Occlusion);
                    md[material].Show_OcclusionMap = Func.TriangleFoldout(md[material].Show_OcclusionMap, ()=> {
                        propTileOffset(_OcclusionMap);
                        prop(_OcclusionMapUV, false);
                    });
                    Func.sRGBWarning(_OcclusionMapUV);
                }




                prop(_BumpMap, _BumpMap.textureValue ? _BumpScale : null);

                md[material].Show_BumpMap = Func.TriangleFoldout(md[material].Show_BumpMap, ()=> {
                    propTileOffset(_BumpMap);
                    prop(_BumpMapUV, false);
                    prop(_NormalMapOrientation, false);
                });
                

                prop(_DetailMap);
                md[material].Show_DetailMap = Func.TriangleFoldout(md[material].Show_DetailMap, ()=> {
                    propTileOffset(_DetailMap);
                    prop(_DetailMapUV, false);
                    prop(_DetailAlbedoScale);
                    prop(_DetailNormalScale);
                    prop(_DetailSmoothnessScale);
                });


                


            });

            md[material].ShowShaderFeatures = Foldout("Shader Features", md[material].ShowShaderFeatures, ()=> {
                prop(_GlossyReflections, false);
                prop(_SpecularHighlights, false);

                if(_GlossyReflections.floatValue == 1 || _SpecularHighlights.floatValue == 1)
                {
                    Func.PropertyGroup(() => {
                    prop(_FresnelColor);
                    prop(_Reflectance);
                    prop(_Anisotropy);
                    });
                }

                prop(_EnableEmission, false);

                if(_EnableEmission.floatValue == 1)
                {
                    Func.PropertyGroup(() => {
                        prop(_EmissionMap, _EmissionColor);

                        md[material].Show_EmissionMap = Func.TriangleFoldout(md[material].Show_EmissionMap, ()=> {
                            propTileOffset(_EmissionMap);
                            prop(_EmissionMapUV, false);
                        });
                        me.LightmapEmissionProperty();

                        if(_EnableAudioLink.floatValue == 1)
                        {
                            EditorGUILayout.Space();;
                            prop(_ALEmissionType);
                            if(_ALEmissionType.floatValue != 0){
                                prop(_ALEmissionBand);
                                prop(_ALEmissionMap);
                                Func.sRGBWarning(_ALEmissionMap);
                            }
                        }
                    });
                }

                prop(_EnableParallax, false);

                if(_EnableParallax.floatValue == 1)
                {
                    Func.PropertyGroup(() => {
                        prop(_ParallaxMap, _Parallax);
                        Func.sRGBWarning(_ParallaxMap);
                        prop(_ParallaxOffset, false);
                        prop(_ParallaxSteps, false);
                    });
                }
                

                prop(_GSAA, false);
                if(_GSAA.floatValue == 1){
                    Func.PropertyGroup(() => {
                        prop(_specularAntiAliasingVariance);
                        prop(_specularAntiAliasingThreshold);
                    });
                };

                prop(_EnableRefraction, false);
                if(_EnableRefraction.floatValue == 1){
                    Func.PropertyGroup(() => {
                        prop(_Refraction);
                    });
                };

                prop(_EnableAudioLink);
                if(_EnableAudioLink.floatValue == 1){
                    Func.PropertyGroup(() => {
                    prop(_AudioTexture);
                    prop(_ALSmoothing);
                    });
                };

                prop(_LodCrossFade);
                prop(_FlatShading);

            });

            md[material].ShowBakedLight = Foldout("Baked Light", md[material].ShowBakedLight, ()=> {
                prop(_SpecularOcclusion);
                prop(_LightmapMultiplier);
                prop(_LightProbeMethod, false);
                prop(_BicubicLightmap, false);
                
                #if BAKERY_INCLUDED
                EditorGUILayout.Space();;
                Func.PropertyGroup(() => {
                    EditorGUILayout.LabelField("Bakery", EditorStyles.boldLabel);
                    prop(_BAKERY_SH, false);
                    if(_BAKERY_SH.floatValue == 1) prop(_BAKERY_SHNONLINEAR, false);
                    prop(_BAKERY_RNM, false);
                    prop(_BAKERY_LMSPEC, false);
                    EditorGUI.BeginDisabledGroup(true);
                    if(_BAKERY_SH.floatValue == 1 || _BAKERY_RNM.floatValue == 1 || _BAKERY_LMSPEC.floatValue == 1)
                    {
                        prop(bakeryLightmapMode, false);
                        prop(_RNM0, false);
                        prop(_RNM1, false);
                        prop(_RNM2, false);
                    }
                    EditorGUI.EndDisabledGroup();
                });
                #endif
            });


            md[material].ShowAdvanced = Foldout("Advanced", md[material].ShowAdvanced, ()=> {
                prop(_GetDominantLight, false);
                prop(_EnablePackedMode);

                EditorGUILayout.Space();;
                me.DoubleSidedGIField();
                me.EnableInstancingField();
                me.RenderQueueField();
                prop(_Cull);
                EditorGUILayout.Space();;
                ListAnimatedProps();
            });

            

            



        }

        // On inspector change
        private void ApplyChanges()
        {
            if(_IsMaterialLocked.floatValue != 0) return;
            Func.SetupGIFlags(_EnableEmission.floatValue, material);
        }

        protected static Dictionary<Material, LitFoldoutDictionary> md = new Dictionary<Material, LitFoldoutDictionary>();
        protected BindingFlags bindingFlags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static;
        MaterialEditor me;
        public bool m_FirstTimeApply = true;
        protected MaterialProperty _IsMaterialLocked = null;

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
            
            Func.ShaderOptimizerButton(_IsMaterialLocked, me);
            isLocked = _IsMaterialLocked.floatValue == 1;
            EditorGUI.BeginChangeCheck();
            EditorGUI.indentLevel++;

            ShaderPropertiesGUI(material);

            if (EditorGUI.EndChangeCheck()) {
                ApplyChanges();
            };
        }

        private void prop(MaterialProperty property) => Func.MaterialProp(property, null, true, me, isLocked, material);
        private void prop(MaterialProperty property, bool isAnimatable) => Func.MaterialProp(property, null, isAnimatable, me, isLocked, material);
        private void prop(MaterialProperty property, MaterialProperty extraProperty) => Func.MaterialProp(property, extraProperty, true, me, isLocked, material);
        
        private void propTileOffset(MaterialProperty property) => Func.propTileOffset(property, isLocked, me, material);
        private void ListAnimatedProps() => Func.ListAnimatedProps(isLocked, allProps, material);
        private bool Foldout(string foldoutText, bool foldoutName, Action action) => Func.Foldout(foldoutText, foldoutName, action);

        

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
        public static string litShaderName = "Lit/lit";

        [MenuItem("Tools/Lit/Standard -> Lit")]
        public static void SwitchToLit()
        {
            List<Material> mats = ShaderOptimizer.GetAllMaterialsWithShader("Standard");
            int progress = mats.Count;

            Shader lit = Shader.Find(litShaderName);

            for (int i=0; i<progress; i++)
            {
                EditorUtility.DisplayCancelableProgressBar("Replacing Shaders", mats[i].name, i/progress);
                mats[i].shader = lit;
            }
            EditorUtility.ClearProgressBar();
        }

        [MenuItem("Tools/Lit/Lit -> Standard")]
        public static void SwitchToStandard()
        {
            List<Material> mats = ShaderOptimizer.GetAllMaterialsWithShader(litShaderName);
            int progress = mats.Count;

            Shader standard = Shader.Find("Standard");

            for (int i=0; i<progress; i++)
            {
                EditorUtility.DisplayCancelableProgressBar("Replacing Shaders", mats[i].name, i/progress);
                mats[i].shader = standard;
            }
            EditorUtility.ClearProgressBar();
        }
    }
}