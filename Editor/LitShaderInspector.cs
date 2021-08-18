using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;
using System.Reflection;

namespace Shaders.Lit
{
    public partial class PersistentData
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
        protected static Dictionary<Material, PersistentData> MaterialData = new Dictionary<Material, PersistentData>();
        protected BindingFlags bindingFlags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static;

        //Assign all properties as null at first to stop hundreds of warnings spamming the log when script gets compiled.
        //If they aren't we get warnings, because assigning with reflection seems to make Unity think that the properties never actually get used.
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

        


        MaterialEditor me;
        public bool m_FirstTimeApply = true;

        protected MaterialProperty _ShaderOptimizerEnabled = null;
        const string AnimatedPropertySuffix = "Animated";
        const char ParseSplitSeparator = '/';
        //bool afterShaderOptimizerButton = false;
        MaterialProperty shaderOptimizer;
        bool[] propertyAnimated;

        private Material material;


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


                ApplyChanges(material);
                m_FirstTimeApply = false;
            }
            ShaderOptimizerButton(_ShaderOptimizerEnabled,me);
            EditorGUILayout.Space(4);
            ShaderPropertiesGUI(material);
        }

        public void ShaderPropertiesGUI(Material material)
        {
            // Use default labelWidth
            EditorGUIUtility.labelWidth = 0f;

            EditorGUI.BeginDisabledGroup(_ShaderOptimizerEnabled.floatValue == 1);

            // Detect any changes to the material
            EditorGUI.BeginChangeCheck();
            {

                EditorGUI.indentLevel++;
                MaterialData[material].ShowSurfaceInputs = Styles.ShurikenFoldout("Surface Inputs", MaterialData[material].ShowSurfaceInputs);
                if(MaterialData[material].ShowSurfaceInputs)
                {
                    EditorGUILayout.Space();

                    EditorGUI.BeginChangeCheck();
                    prop(_Mode);
                    if (EditorGUI.EndChangeCheck()) SetupMaterialWithBlendMode(material);
                    if(_Mode.floatValue == 1){
                        prop(_AlphaToMask);
                        prop(_Cutoff);
                    }
                    EditorGUILayout.Space();
                    
                    
                    prop(_MainTex, _Color);
                    MaterialData[material].Show_MainTex = Styles.TextureFoldout(MaterialData[material].Show_MainTex);
                    if(MaterialData[material].Show_MainTex){
                        Styles.PropertyGroup(() => {
                        me.TextureScaleOffsetProperty(_MainTex);
                        prop(_MainTexUV);
                        prop(_Saturation);
                        });
                    }

                    prop(_Metallic);
                    prop(_Glossiness);

                    if (_MetallicGlossMap.textureValue) prop(_Occlusion);

                    prop(_MetallicGlossMap);
                    MaterialData[material].Show_MetallicGlossMap = Styles.TextureFoldout(MaterialData[material].Show_MetallicGlossMap);
                    Styles.sRGBWarning(_MetallicGlossMap);
                    if(MaterialData[material].Show_MetallicGlossMap){
                        Styles.PropertyGroup(() => {
                        me.TextureScaleOffsetProperty(_MetallicGlossMap);
                        prop(_MetallicGlossMapUV);
                        });
                    }

                    prop(_BumpMap, _BumpMap.textureValue ? _BumpScale : null);

                    MaterialData[material].Show_BumpMap = Styles.TextureFoldout(MaterialData[material].Show_BumpMap);
                    if(MaterialData[material].Show_BumpMap){
                        Styles.PropertyGroup(() => {
                        me.TextureScaleOffsetProperty(_BumpMap);
                        prop(_BumpMapUV);
                        prop(_NormalMapOrientation);
                        });
                    }

                    prop(_EnableEmission);

                    if(_EnableEmission.floatValue == 1){
                        prop(_EmissionMap, _EmissionColor);
                        MaterialData[material].Show_EmissionMap = Styles.TextureFoldout(MaterialData[material].Show_EmissionMap);
                        if(MaterialData[material].Show_EmissionMap){
                            Styles.PropertyGroup(() => {
                            me.TextureScaleOffsetProperty(_EmissionMap);
                            prop(_EmissionMapUV);

                        
                        });
                    }
                    }

                    EditorGUILayout.Space();
                    




                }
                
                
            }

            MaterialData[material].ShowSpecular = Styles.ShurikenFoldout("Specular Reflections", MaterialData[material].ShowSpecular);
            if(MaterialData[material].ShowSpecular)
            {
                EditorGUILayout.Space();
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
                me.ShaderProperty(_EnableMatcap, "Matcap");
                if(_EnableMatcap.floatValue == 1){
                    Styles.PropertyGroup(() => {
                    prop(_MatCap);
                    prop(_MatCapReplace);
                    });
                };
                EditorGUILayout.Space();
                prop(_GlossyReflections);
                prop(_SpecularHighlights);

                EditorGUILayout.Space();

            }

            MaterialData[material].ShowBakedLight = Styles.ShurikenFoldout("Baked Light", MaterialData[material].ShowBakedLight);
            if(MaterialData[material].ShowBakedLight)
            {
                EditorGUILayout.Space();                
                prop(_LightmapMultiplier);
                prop(_SpecularOcclusion);

                EditorGUILayout.Space();
                prop(_BicubicLightmap);
                prop(_LightProbeMethod);

                EditorGUILayout.Space();
            }


            MaterialData[material].ShowAdvanced = Styles.ShurikenFoldout("Advanced Options", MaterialData[material].ShowAdvanced);
            if(MaterialData[material].ShowAdvanced)
            {
                EditorGUILayout.Space();
                prop(_TonemappingMode);
                if(_TonemappingMode.floatValue == 1) prop(_Contribution);

                EditorGUILayout.Space();
                prop(_Cull);

                me.EnableInstancingField();
                me.DoubleSidedGIField();
                me.RenderQueueField();
            }


            if (EditorGUI.EndChangeCheck()) ApplyChanges(material);
            EditorGUI.EndDisabledGroup();
        }

        public void ApplyChanges(Material m){
            if(_ShaderOptimizerEnabled.floatValue == 0){
                
           
            }
        }

        private void prop(MaterialProperty property) => DrawProperty(property, null);
        private void prop(MaterialProperty property, MaterialProperty extraProperty) => DrawProperty(property, extraProperty);

        private void DrawProperty(MaterialProperty property, MaterialProperty extraProperty)
        {
            string[] propertyName = property.displayName.Split('/');
            string displayName = propertyName[0];
            string propParameters = propertyName.Length == 2 ? propertyName[1] : null;

            if(ParseShowIf(propParameters)){

                if(property.type == MaterialProperty.PropType.Range ||
                    property.type == MaterialProperty.PropType.Float ||
                    property.type == MaterialProperty.PropType.Vector ||
                    property.type == MaterialProperty.PropType.Color) me.ShaderProperty(property, displayName);

                if(property.type == MaterialProperty.PropType.Texture)
                {
                    me.TexturePropertySingleLine(new GUIContent(displayName, ParseHover(propParameters)), property, extraProperty);
                }
            }
        }

        private bool ParseShowIf(string a){
            if(a == null) return true; 
            string[] d = a.Split(',');

            foreach(string e in d)
            {
                string[] f = e.Split(':');

                if(f[0] == "showif")
                {
                    string[] h = f[1].Split('=');
                    if(material.GetFloat(h[0]) == float.Parse(h[1])) return true;
                    else return false;
                }
            }
            return true;
        }

        private string ParseHover(string a){
            if(a == null) return null; 
            string[] d = a.Split(',');

            foreach(string e in d)
            {
                string[] f = e.Split(':');

                if(f[0] == "hover") return f[1];

            }
            return null;
        }

        



        static void SetKeyword(Material m, string keyword, bool state)
        {
            if (state) m.EnableKeyword(keyword); else m.DisableKeyword(keyword);
        }

        static void SetKeyword(Material m, string keyword, float state) 
        {
            if (state == 1) m.EnableKeyword(keyword); else m.DisableKeyword(keyword);
        }

        private void SetupFoldoutDictionary(Material material)
        {
            if (MaterialData.ContainsKey(material))
                return;

            PersistentData toggles = new PersistentData();
            MaterialData.Add(material, toggles);
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