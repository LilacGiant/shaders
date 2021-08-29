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
        public bool AnimatedProps = false;

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
                prop(_Mode, false);
                if (EditorGUI.EndChangeCheck()) SetupMaterialWithBlendMode(material);

                if(_Mode.floatValue == 1){
                    prop(_AlphaToMask);
                    prop(_Cutoff);
                }
                Space();
                
                prop(_MainTex, _Color);

                md[material].Show_MainTex = TriangleFoldout(md[material].Show_MainTex, ()=> {
                    propTileOffset(_MainTex);
                    prop(_MainTexUV, false);
                    prop(_Saturation);
                });


                prop(_Metallic);
                prop(_Glossiness);

                if (_MetallicGlossMap.textureValue) prop(_Occlusion);

                prop(_MetallicGlossMap);
                md[material].Show_MetallicGlossMap = TriangleFoldout(md[material].Show_MetallicGlossMap, ()=> {
                    propTileOffset(_MetallicGlossMap);
                    prop(_MetallicGlossMapUV, false);
                });

                Styles.sRGBWarning(_MetallicGlossMap);


                prop(_BumpMap, _BumpMap.textureValue ? _BumpScale : null);

                md[material].Show_BumpMap = TriangleFoldout(md[material].Show_BumpMap, ()=> {
                    propTileOffset(_BumpMap);
                    prop(_BumpMapUV, false);
                    prop(_NormalMapOrientation, false);
                });


                prop(_EnableEmission, false);

                if(_EnableEmission.floatValue == 1){
                    prop(_EmissionMap, _EmissionColor);

                    md[material].Show_EmissionMap = TriangleFoldout(md[material].Show_EmissionMap, ()=> {
                        propTileOffset(_EmissionMap);
                        prop(_EmissionMapUV, false);
                        me.LightmapEmissionProperty();
                    });
                }
            });


            md[material].ShowSpecular = Foldout("Specular Reflections", md[material].ShowSpecular, ()=> {
                prop(_GetDominantLight, false);
                prop(_FresnelColor);
                prop(_Reflectance);
                prop(_AngularGlossiness);
                prop(_Anisotropy);

                prop(_GSAA, false);
                if(_GSAA.floatValue == 1){
                    Styles.PropertyGroup(() => {
                        prop(_specularAntiAliasingVariance);
                        prop(_specularAntiAliasingThreshold);
                    });
                };

                prop(_EnableMatcap, false);
                if(_EnableMatcap.floatValue == 1){
                    Styles.PropertyGroup(() => {
                    prop(_MatCap);
                    prop(_MatCapReplace);
                    });
                };

                Space();
                prop(_GlossyReflections, false);
                prop(_SpecularHighlights, false);
            });

            md[material].ShowBakedLight = Foldout("Baked Light", md[material].ShowBakedLight, ()=> {
                prop(_LightmapMultiplier);
                prop(_SpecularOcclusion);
                Space();

                prop(_BicubicLightmap, false);
                prop(_LightProbeMethod, false);
            });


            md[material].ShowAdvanced = Foldout("Advanced", md[material].ShowAdvanced, ()=> {
                prop(_TonemappingMode, false);
                if(_TonemappingMode.floatValue == 1) prop(_Contribution);
                Space();
                
                prop(_Cull);
                me.EnableInstancingField();
                me.DoubleSidedGIField();
                me.RenderQueueField();
            });

            ListAnimatedProps();



        }



        private void ApplyChanges()
        {
            if(_ShaderOptimizerEnabled.floatValue != 0) return;

            SetupGIFlags(_EnableEmission.floatValue);
                
                
                    

            
        }

        protected static Dictionary<Material, FoldoutDictionary> md = new Dictionary<Material, FoldoutDictionary>();
        protected BindingFlags bindingFlags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static;

        MaterialEditor me;
        public bool m_FirstTimeApply = true;

        protected MaterialProperty _ShaderOptimizerEnabled = null;
        const string AnimatedPropertySuffix = "Animated";
        const char hoverSplitSeparator = ':';
        bool[] propertyAnimated;
        public bool isLocked;
        Material material = null;
        MaterialProperty[] allProps;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            FindProperties(props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
            me = materialEditor;
            material = materialEditor.target as Material;
            SetupFoldoutDictionary(material);
            allProps = props;

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
            isLocked = _ShaderOptimizerEnabled.floatValue == 1;
            EditorGUI.BeginChangeCheck();
            EditorGUI.indentLevel++;

            ShaderPropertiesGUI(material);

            if (EditorGUI.EndChangeCheck()) {
                ApplyChanges();
            };
        }

        public void prop(MaterialProperty property) => MaterialProp(property, null, true);
        public void prop(MaterialProperty property, bool isAnimatable) => MaterialProp(property, null, isAnimatable);
        public void prop(MaterialProperty property, MaterialProperty extraProperty) => MaterialProp(property, extraProperty, true);
       


        public void MaterialProp(MaterialProperty property, MaterialProperty extraProperty, bool isAnimatable)
        {

            EditorGUI.BeginDisabledGroup(isLocked);

            string animatedPropName = null;
            bool drawRight = false;

            if( property.type == MaterialProperty.PropType.Range ||
                property.type == MaterialProperty.PropType.Float ||
                property.type == MaterialProperty.PropType.Vector ||
                property.type == MaterialProperty.PropType.Color)
            {
                me.ShaderProperty(property, property.displayName);
                animatedPropName = property.name.ToString();

            }

            if(property.type == MaterialProperty.PropType.Texture) 
            {
                string[] p = property.displayName.Split(hoverSplitSeparator);
                animatedPropName = extraProperty != null ? extraProperty.name.ToString() : null;
                drawRight = true;


                me.TexturePropertySingleLine(new GUIContent(p[0], p.Length == 2 ? p[1] : null), property, extraProperty);
            }

            if(isAnimatable) AnimatedPropertyToggle(animatedPropName, drawRight);

            EditorGUI.EndDisabledGroup();
            



            
        }

        private void ListAnimatedProps()
        {
            //EditorGUILayout.LabelField("Unlocked Properties", new GUIStyle("BoldLabel"));
            
            //md[material].AnimatedProps = TriangleFoldout(md[material].AnimatedProps, ()=> {
            md[material].AnimatedProps = Foldout("Unlocked Properties", md[material].AnimatedProps, ()=> {

                EditorGUI.indentLevel--;
                EditorGUILayout.HelpBox("Middle click a property to make it animatable when locked in", MessageType.Info);
                EditorGUI.indentLevel++;

                foreach(MaterialProperty property in allProps){
                    string animatedName = property.name + AnimatedPropertySuffix;
                    bool isAnimated = material.GetTag(animatedName, false) == "" ? false : true;
                    if (isAnimated)
                    { 
                        EditorGUILayout.LabelField(property.displayName);
                        Rect lastRect = GUILayoutUtility.GetLastRect();
                        Rect x = new Rect(lastRect.x, lastRect.y + 4f, 15f, 12f);
                        GUI.DrawTexture(x, Styles.xTex);

                        var e = Event.current;
                        if (e.type == EventType.MouseDown && x.Contains(e.mousePosition) && e.button == 0)
                        {
                            e.Use();
                            material.SetOverrideTag(animatedName, "");
                        }
                    }
                }
            });
        }

        private void AnimatedPropertyToggle (string k, bool drawRight)
        {
            if(k == null) return;
            string animatedName = k + AnimatedPropertySuffix;
            bool isAnimated = material.GetTag(animatedName, false) == "" ? false : true;
            var e = Event.current;

            if (e.type == EventType.MouseDown && GUILayoutUtility.GetLastRect().Contains(e.mousePosition) && e.button == 2)
            {
                e.Use();
                material.SetOverrideTag(animatedName, isAnimated ? "" : "1");
            }
            if(isAnimated)
            {
                Rect lastRect = GUILayoutUtility.GetLastRect();
                Rect stopWatch = new Rect(drawRight ? Screen.width - 28f : lastRect.x, lastRect.y  + (drawRight ? 3f : 4f), 12f, 12f);

                GUI.DrawTexture(stopWatch, Styles.animatedTex);

            }
        }

        public void propTileOffset(MaterialProperty property)
        {
            EditorGUI.BeginDisabledGroup(isLocked);
            me.TextureScaleOffsetProperty(property);
            AnimatedPropertyToggle(property.name.ToString(), false);
            EditorGUI.EndDisabledGroup();
        }

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

        public void SetupGIFlags(float emissionEnabled)
        {
            MaterialGlobalIlluminationFlags flags = material.globalIlluminationFlags;
            if ((flags & (MaterialGlobalIlluminationFlags.BakedEmissive | MaterialGlobalIlluminationFlags.RealtimeEmissive)) != 0)
            {
                flags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                if (emissionEnabled != 1)
                    flags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;

                material.globalIlluminationFlags = flags;
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