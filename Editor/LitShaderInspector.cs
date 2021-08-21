using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;
using System.Reflection;

namespace Shaders.Lit
{
    public partial class FoldoutDictionary
    {
        public bool ShowSurfaceInputs = true;
        public bool ShowSpecular = false;
        public bool ShowAdvanced = false;
        public bool ShowBakedLight = false;

        public bool Show_MainTex = false;
        public bool Show_MetallicGlossMap = false;
        public bool Show_BumpMap = false;
        public bool Show_EmissionMap = false;

    }
    
    public class ShaderEditor : ShaderGUI
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
        protected MaterialProperty _AngularGlossiness = null;
        protected MaterialProperty _GSAA = null;
        protected MaterialProperty _specularAntiAliasingVariance = null;
        protected MaterialProperty _specularAntiAliasingThreshold = null;
        protected MaterialProperty _FresnelColor = null;
        protected MaterialProperty _BicubicLightmap = null;
        protected MaterialProperty _LightmapMultiplier = null;
        protected MaterialProperty _SpecularOcclusion = null;
        protected MaterialProperty _LightProbeMethod = null;
        protected MaterialProperty _TonemappingMode = null;
        protected MaterialProperty _Contribution = null;
        protected MaterialProperty _Anisotropy = null;
        protected MaterialProperty _EnableMatcap = null;
        protected MaterialProperty _MatCapReplace = null;
        protected MaterialProperty _MatCap = null;
        protected MaterialProperty _Cull = null;




        public void ShaderPropertiesGUI(Material material)
        {

            md[material].ShowSurfaceInputs = Foldout("Surface Inputs", md[material].ShowSurfaceInputs, ()=> {

                EditorGUI.BeginChangeCheck();
                prop(_Mode);
                if (EditorGUI.EndChangeCheck()) SetupMaterialWithBlendMode(material);

                if(_Mode.floatValue == 1){
                    prop(_AlphaToMask);
                    prop(_Cutoff);
                }
                Space();
                
                prop(_MainTex, _Color);

                md[material].Show_MainTex = TriangleFoldout(md[material].Show_MainTex, ()=> {
                    me.TextureScaleOffsetProperty(_MainTex);
                    prop(_MainTexUV);
                    prop(_Saturation);
                });


                prop(_Metallic);
                prop(_Glossiness);

                if (_MetallicGlossMap.textureValue) prop(_Occlusion);

                prop(_MetallicGlossMap);
                md[material].Show_MetallicGlossMap = TriangleFoldout(md[material].Show_MetallicGlossMap, ()=> {
                    prop(_MetallicGlossMap);
                    prop(_MetallicGlossMapUV);
                });


                prop(_BumpMap, _BumpMap.textureValue ? _BumpScale : null);

                md[material].Show_BumpMap = TriangleFoldout(md[material].Show_BumpMap, ()=> {
                    me.TextureScaleOffsetProperty(_BumpMap);
                    prop(_BumpMapUV);
                    prop(_NormalMapOrientation);
                });


                prop(_EnableEmission);

                if(_EnableEmission.floatValue == 1){
                    prop(_EmissionMap, _EmissionColor);

                    md[material].Show_EmissionMap = TriangleFoldout(md[material].Show_EmissionMap, ()=> {
                        me.TextureScaleOffsetProperty(_EmissionMap);
                        prop(_EmissionMapUV);
                    });
                }

                




            });


            md[material].ShowSpecular = Foldout("Specular Reflections", md[material].ShowSpecular, ()=> {
                prop(_GetDominantLight);
                prop(_FresnelColor);
                prop(_Reflectance);
                prop(_AngularGlossiness);
                prop(_Anisotropy);

                prop(_GSAA);
                if(_GSAA.floatValue == 1){
                    Styles.PropertyGroup(() => {
                        prop(_specularAntiAliasingVariance);
                        prop(_specularAntiAliasingThreshold);
                    });
                };

                prop(_EnableMatcap);
                if(_EnableMatcap.floatValue == 1){
                    Styles.PropertyGroup(() => {
                    prop(_MatCap);
                    prop(_MatCapReplace);
                    });
                };

                Space();
                prop(_GlossyReflections);
                prop(_SpecularHighlights);
            });


            md[material].ShowBakedLight = Foldout("Baked Light", md[material].ShowBakedLight, ()=> {
                prop(_LightmapMultiplier);
                prop(_SpecularOcclusion);
                Space();

                prop(_BicubicLightmap);
                prop(_LightProbeMethod);
            });


            md[material].ShowAdvanced = Foldout("Advanced Options", md[material].ShowAdvanced, ()=> {
                prop(_TonemappingMode);
                if(_TonemappingMode.floatValue == 1) prop(_Contribution);
                Space();
                
                prop(_Cull);
                me.EnableInstancingField();
                me.DoubleSidedGIField();
                me.RenderQueueField();
            });



        }

        protected static Dictionary<Material, FoldoutDictionary> md = new Dictionary<Material, FoldoutDictionary>();
        protected BindingFlags bindingFlags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static;

        MaterialEditor me;
        public bool m_FirstTimeApply = true;

        protected MaterialProperty _ShaderOptimizerEnabled = null;
        const string AnimatedPropertySuffix = "Animated";
        const char hoverSplitSeparator = ':';
        bool[] propertyAnimated;
        Material material = null;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            FindProperties(props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
            me = materialEditor;
            material = materialEditor.target as Material;
            SetupFoldoutDictionary(material);

            // Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
            // material to a standard shader.
            // Do this before any GUI code has been issued to prevent layout issues in subsequent GUILayout statements (case 780071)
            if (m_FirstTimeApply)
            {
                
                // Cache the animated state of each property to exclude them from being disabled when the material is locked
                if (propertyAnimated == null)
                    propertyAnimated = new bool[props.Length];
                string uniquePropertyNamesSuffix = ((Material)materialEditor.target).GetTag("AnimatedParametersSuffix", false, "");
                for (int i=0;i<props.Length;i++)
                {
                    propertyAnimated[i] = false;
                    string animatedPropertyName = props[i].name + AnimatedPropertySuffix;
                    MaterialProperty animProp = FindProperty(animatedPropertyName, props, false);
                    if (animProp == null && uniquePropertyNamesSuffix != "")
                        animProp = FindProperty(animatedPropertyName.Replace(uniquePropertyNamesSuffix, ""), props, false);
                    if (animProp != null)
                        propertyAnimated[i] = (animProp.floatValue == 1);
                }


                m_FirstTimeApply = false;
            }
            
            ShaderOptimizerButton(_ShaderOptimizerEnabled, me);

            EditorGUI.BeginDisabledGroup(_ShaderOptimizerEnabled.floatValue == 1);
            EditorGUI.BeginChangeCheck();
            EditorGUI.indentLevel++;

            ShaderPropertiesGUI(material);

            if (EditorGUI.EndChangeCheck()) {};
            EditorGUI.EndDisabledGroup();
        }

        public void prop(MaterialProperty property) => MaterialProp(property, null);
        public void prop(MaterialProperty property, MaterialProperty extraProperty) => MaterialProp(property, extraProperty);

        private void Space() => EditorGUILayout.Space();
        private void Space(int a) => EditorGUILayout.Space(a);

        public bool Foldout(string foldoutText, bool foldoutName, Action action)
        {
            foldoutName = Styles.Foldout(foldoutText, foldoutName);
            if(foldoutName)
            {
                Space();
			    action();
                Space();
            }
            return foldoutName;
        }

        public bool TriangleFoldout(bool foldoutName, Action action)
        {
            foldoutName = Styles.TextureFoldout(foldoutName);
            if(foldoutName)
            {
                Styles.PropertyGroup(() => {
                    action();
                });
            }
            return foldoutName;
        }




        public void MaterialProp(MaterialProperty property, MaterialProperty extraProperty)
        {
            if(property.type == MaterialProperty.PropType.Range ||
               property.type == MaterialProperty.PropType.Float ||
               property.type == MaterialProperty.PropType.Vector ||
               property.type == MaterialProperty.PropType.Color) me.ShaderProperty(property, property.displayName);

            if(property.type == MaterialProperty.PropType.Texture) 
            {
                string[] p = property.displayName.Split(hoverSplitSeparator);

                me.TexturePropertySingleLine(new GUIContent(p[0], p.Length == 2 ? p[1] : null), property, extraProperty);
            }
        }




        private void SetupFoldoutDictionary(Material material)
        {
            if (md.ContainsKey(material)) return;

            FoldoutDictionary toggles = new FoldoutDictionary();
            md.Add(material, toggles);
        }

        public void ShaderOptimizerButton(MaterialProperty shaderOptimizer, MaterialEditor materialEditor)
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
                                m_FirstTimeApply = true;
                        }
                    }
                    else
                    {
                        foreach (Material m in materialEditor.targets)
                            if (!ShaderOptimizer.Unlock(m))
                                m.SetFloat(shaderOptimizer.name, 1);
                                m_FirstTimeApply = true;
                    }
                }
            }
            EditorGUILayout.Space(4);
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

        public void SetupMaterialWithBlendMode(Material material)
        {
            switch (_Mode.floatValue)
            {
                case 0:
                    material.SetOverrideTag("RenderType", "");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.renderQueue = -1;
                    break;
                case 1:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    break;
                case 2:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case 3:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
            }
        }


    }
}