using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System;
using System.Reflection;

namespace Lit
{
    public partial class FoldoutToggles
    {
        public bool ShowSurfaceInputs = true;
        public bool ShowSpecular = false;
        public bool ShowAdvanced = false;

        public bool Show_MainTex = false;
        public bool Show_MetallicGlossMap = false;
        public bool Show_BumpMap = false;
        public bool Show_EmissionMap = false;
    }


    public class ShaderEditor : ShaderGUI
    {
        protected static Dictionary<Material, FoldoutToggles> Foldouts = new Dictionary<Material, FoldoutToggles>();
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
        protected MaterialProperty _EnablePackedMap = null;
        protected MaterialProperty _EnableNormalMap = null;
        protected MaterialProperty _SpecularHighlights = null;
        protected MaterialProperty _GlossyReflections = null;
        
        


        MaterialEditor m_MaterialEditor;
        public bool m_FirstTimeApply = true;

        protected MaterialProperty _ShaderOptimizerEnabled = null;
        const string AnimatedPropertySuffix = "Animated";
        //bool afterShaderOptimizerButton = false;
        MaterialProperty shaderOptimizer;
        bool[] propertyAnimated;

        

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
            m_MaterialEditor = materialEditor;
            Material material = materialEditor.target as Material;
            SetupFoldoutDictionary(material);

            // Make sure that needed setup (ie keywords/renderqueue) are set up if we're switching some existing
            // material to a standard shader.
            // Do this before any GUI code has been issued to prevent layout issues in subsequent GUILayout statements (case 780071)
            if (m_FirstTimeApply)
            {
                

                // Clear all keywords to begin with, in case there are conflicts with different shaders
                foreach (Material m in materialEditor.targets)
                    foreach (string keyword in m.shaderKeywords)
                        m.DisableKeyword(keyword);
                
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
            ShaderOptimizerButton(_ShaderOptimizerEnabled,m_MaterialEditor);
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
                Foldouts[material].ShowSurfaceInputs = LitStyles.ShurikenFoldout("Surface Inputs", Foldouts[material].ShowSurfaceInputs);
                if(Foldouts[material].ShowSurfaceInputs)
                {
                    EditorGUILayout.Space();
                    
                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("Base Map", "RGBA"), _MainTex, _Color);
                    Foldouts[material].Show_MainTex = LitStyles.TextureFoldout(Foldouts[material].Show_MainTex);
                    if(Foldouts[material].Show_MainTex){
                        LitStyles.PropertyGroup(() => {
                        m_MaterialEditor.TextureScaleOffsetProperty(_MainTex);
                        m_MaterialEditor.ShaderProperty(_MainTexUV, "UV");
                        m_MaterialEditor.ShaderProperty(_Saturation, "Saturation");
                        });
                    }

                    m_MaterialEditor.ShaderProperty(_Metallic, "Metallic");
                    m_MaterialEditor.ShaderProperty(_Glossiness, "Smoothness");
                    if (_MetallicGlossMap.textureValue) m_MaterialEditor.ShaderProperty(_Occlusion, "Occlusion");

                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("Mask Map", "Metallic(R), Occlusion(G), Detail Mask(B), Smoothness(A)"), _MetallicGlossMap);
                    Foldouts[material].Show_MetallicGlossMap = LitStyles.TextureFoldout(Foldouts[material].Show_MetallicGlossMap);
                    LitStyles.sRGBWarning(_MetallicGlossMap);
                    if(Foldouts[material].Show_MetallicGlossMap){
                        LitStyles.PropertyGroup(() => {
                        m_MaterialEditor.TextureScaleOffsetProperty(_MetallicGlossMap);
                        m_MaterialEditor.ShaderProperty(_MetallicGlossMapUV, "UV");
                        });
                    }

                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("Normal Map"), _BumpMap,  _BumpMap.textureValue ? _BumpScale : null);
                    Foldouts[material].Show_BumpMap = LitStyles.TextureFoldout(Foldouts[material].Show_BumpMap);
                    if(Foldouts[material].Show_BumpMap){
                        LitStyles.PropertyGroup(() => {
                        m_MaterialEditor.TextureScaleOffsetProperty(_BumpMap);
                        m_MaterialEditor.ShaderProperty(_BumpMapUV, "UV");
                        m_MaterialEditor.ShaderProperty(_NormalMapOrientation, "Orientation");
                        });
                    }

                    m_MaterialEditor.ShaderProperty(_EnableEmission, "Emission");
                    if(_EnableEmission.floatValue == 1){
                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("Color"), _EmissionMap, _EmissionColor);
                    Foldouts[material].Show_EmissionMap = LitStyles.TextureFoldout(Foldouts[material].Show_EmissionMap);
                    if(Foldouts[material].Show_EmissionMap){
                        LitStyles.PropertyGroup(() => {
                        m_MaterialEditor.TextureScaleOffsetProperty(_EmissionMap);
                        m_MaterialEditor.ShaderProperty(_EmissionMapUV, "UV");
                        
                        });
                    }
                    }

                    EditorGUILayout.Space();
                    




                }
                
                
            }

            Foldouts[material].ShowSpecular = LitStyles.ShurikenFoldout("Specular", Foldouts[material].ShowSpecular);
            if(Foldouts[material].ShowSpecular)
            {
                m_MaterialEditor.ShaderProperty(_SpecularHighlights, "Specular Highlights");
                m_MaterialEditor.ShaderProperty(_GlossyReflections, "Reflections");
            }


            Foldouts[material].ShowAdvanced = LitStyles.ShurikenFoldout("Advanced Options", Foldouts[material].ShowAdvanced);
            if(Foldouts[material].ShowAdvanced)
            {
                m_MaterialEditor.EnableInstancingField();
                m_MaterialEditor.DoubleSidedGIField();
            }


            if (EditorGUI.EndChangeCheck()) ApplyChanges(material);
            EditorGUI.EndDisabledGroup();
        }

        public void ApplyChanges(Material m){
           if(_ShaderOptimizerEnabled.floatValue == 0){

           // toggles
           if(_MetallicGlossMap.textureValue) _EnablePackedMap.floatValue = 1; else _EnablePackedMap.floatValue = 0;
           if(_BumpMap.textureValue) _EnableNormalMap.floatValue = 1; else _EnableNormalMap.floatValue = 0;


           // keywords
           SetKeyword(m, "_GLOSSYREFLECTIONS_OFF", _GlossyReflections.floatValue);
           SetKeyword(m, "_SPECULARHIGHLIGHTS_OFF", _SpecularHighlights.floatValue);

           
            }
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
            if (Foldouts.ContainsKey(material))
                return;

            FoldoutToggles toggles = new FoldoutToggles();
            Foldouts.Add(material, toggles);
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
                        }
                    }
                    else
                    {
                        foreach (Material m in materialEditor.targets)
                            if (!ShaderOptimizer.Unlock(m))
                                m.SetFloat(shaderOptimizer.name, 1);
                    }
                }
            }
        }






    }
}