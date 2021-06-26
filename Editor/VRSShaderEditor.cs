using UnityEngine;
using UnityEditor;
using System;
using System.Linq;

namespace z3y
{
    public class VRSShaderEditor : ShaderGUI
    {
        private MaterialProperty albedoMap = null;
        private MaterialProperty albedoColor = null;
        
        private MaterialProperty metallicMap = null;
        private MaterialProperty metallicScale = null;

        private MaterialProperty roughnessMap = null;
        private MaterialProperty roughnessScale = null;
        
        private MaterialProperty normalMap = null;
        private MaterialProperty normalScale = null;
        
        private MaterialProperty occlusionMap = null;
        private MaterialProperty occlusionScale = null;

        private MaterialProperty gsaa = null;
        private MaterialProperty gsaaVariance = null;
        private MaterialProperty gsaaThreshold = null;
        
        private MaterialProperty specularHighlightsToggle = null;
        private MaterialProperty specularOcclusion = null;
        private MaterialProperty glossyReflectionsToggle = null;
        private MaterialProperty reflectance = null;
        private MaterialProperty anisotrpy = null;

        public MaterialProperty overrideQuest = null;
        
        

        private void FindProperties(MaterialProperty[] props)
        {
            albedoMap = FindProperty("_MainTex", props);
            albedoColor = FindProperty("_Color", props);

            metallicMap = FindProperty("_MetallicMap", props);
            metallicScale = FindProperty("_Metallic", props);
            
            roughnessMap = FindProperty("_RoughnessMap", props);
            roughnessScale = FindProperty("_Roughness", props);
            
            gsaa = FindProperty("_GSAA", props);
            gsaaVariance = FindProperty("_specularAntiAliasingVariance", props);
            gsaaThreshold = FindProperty("_specularAntiAliasingThreshold", props);
            
            normalMap = FindProperty("_BumpMap", props);
            normalScale = FindProperty("_BumpScale", props);
            
            occlusionMap = FindProperty("_OcclusionMap", props);
            occlusionScale = FindProperty("_OcclusionStrength", props);

            
            specularHighlightsToggle = FindProperty("_SpecularHighlights", props);
            specularOcclusion = FindProperty("_SpecularOcclusion", props);
            glossyReflectionsToggle = FindProperty("_GlossyReflections", props);
            reflectance = FindProperty("_Reflectance", props);
            anisotrpy = FindProperty("_Anisotropy", props);
            
            overrideQuest = FindProperty("_OverrideQuest", props);
        }


        GUIStyle foldoutStyle;
        bool m_FirstTimeApply = true;

        private bool _showAdvanced = true;



       

        
        

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {

            FindProperties(props);

            Material mat = materialEditor.target as Material;

            if (m_FirstTimeApply)
            {
                foreach (Material m in materialEditor.targets)
                foreach (string keyword in m.shaderKeywords)
                    m.DisableKeyword(keyword);

                
                m_FirstTimeApply = false;
                SetMaterialKeywords(mat);
                
                
                
                
            }
            
            

            ShaderPropertiesGUI(mat, materialEditor);
        }
        
        

        private void ShaderPropertiesGUI(Material material, MaterialEditor me)
        {
            
            
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.Space();

            

            me.TexturePropertySingleLine(new GUIContent("Albedo", "Albedo (RGB)"), albedoMap, albedoColor);

            
            me.TexturePropertySingleLine(new GUIContent("Metallic"), metallicMap, metallicScale);
            me.TexturePropertySingleLine(new GUIContent("Roughness"), roughnessMap, roughnessScale);
 
            me.TexturePropertySingleLine(new GUIContent("Normal Map"), normalMap, normalScale);
            
            me.TexturePropertySingleLine(new GUIContent("Occlusion"), occlusionMap, occlusionScale);
            


            EditorGUILayout.Space();
            me.TextureScaleOffsetProperty(albedoMap);

            EditorGUILayout.Space();


            
            
            _showAdvanced = EditorGUILayout.Foldout(_showAdvanced, "Advanced Options", EditorStyles.standardFont);
            if (_showAdvanced)
            {
                EditorGUILayout.Space();
                
                me.ShaderProperty(gsaa, new GUIContent("Geometric Specular AA"), 0);
                me.ShaderProperty(gsaaVariance, new GUIContent("Variance"), 2);
                me.ShaderProperty(gsaaThreshold, new GUIContent("Threshold"), 2);
                EditorGUILayout.Space();

                EditorGUILayout.Space();
                me.ShaderProperty(specularHighlightsToggle, new GUIContent("Specular Highlights"), 0);
                
                me.ShaderProperty(glossyReflectionsToggle, new GUIContent("Reflections"));
                EditorGUILayout.Space();
                me.ShaderProperty(specularOcclusion, new GUIContent("Specular Occlusion"),2);
                me.ShaderProperty(reflectance,new GUIContent("Reflectace"),2);
                
                
                me.ShaderProperty(anisotrpy, new GUIContent("Anisotrpy"));
                
                me.ShaderProperty(overrideQuest, new GUIContent("Override Quest Platform Config"), 0);
                





                EditorGUILayout.Space();





                me.EnableInstancingField();
                me.DoubleSidedGIField();

                EditorGUILayout.Space();
                EditorGUILayout.Separator();

                if (GUILayout.Button("Global Shader Config",GUILayout.MaxWidth(200)))
                {
                    PlatformShaderConfig.ShowWindow();
                }


                me.RenderQueueField();
            }
            

            GUI.enabled = true;


            if (EditorGUI.EndChangeCheck())
            {
                SetMaterialKeywords(material);
            }

        }

        public static void SetMaterialKeywords(Material material)
        {
            SetKeyword(material, "_NORMALMAP", material.GetTexture("_BumpMap"));
            SetKeyword(material, "_METALLICGLOSSMAP", material.GetTexture("_MetallicMap"));
            
            SetKeyword(material, "_SPECGLOSSMAP", material.GetTexture("_RoughnessMap"));
            
            SetKeyword(material, "_DETAIL_MULX2", material.GetTexture("_OcclusionMap"));
            
            SetKeyword(material,"UNITY_UI_CLIP_RECT", Convert.ToBoolean(material.GetInt("_GSAA")));



            

            SetKeyword(material, "_GLOSSYREFLECTIONS_OFF", Convert.ToBoolean(material.GetInt("_GlossyReflections")));
            SetKeyword(material, "_SPECULARHIGHLIGHTS_OFF", Convert.ToBoolean(material.GetInt("_SpecularHighlights")));
        }

        static void SetKeyword(Material m, string key, bool state)
        {
            
            if (PlatformShaderConfig.isQuest == true && m.GetFloat("_OverrideQuest") == 0)
            {
                        if (PlatformShaderConfig.ShaderKeywordsQuest.Contains(key))
                        {
                            if (state) m.EnableKeyword(key);

                        }
                        else
                        {
                            m.DisableKeyword(key);
                        }




            }
            
            else
            {
                if (state) m.EnableKeyword(key);
                else m.DisableKeyword(key);
            }




        }

      


        //Mochie MGUI
        static bool TextureImportWarningBox(string message)
        {
            GUILayout.BeginVertical(new GUIStyle(EditorStyles.helpBox));
            EditorGUILayout.LabelField(message, new GUIStyle(EditorStyles.label)
            {
                fontSize = 9, wordWrap = true
            });
            EditorGUILayout.BeginHorizontal(new GUIStyle()
            {
                alignment = TextAnchor.MiddleRight
            }, GUILayout.Height(0));
            EditorGUILayout.Space();
            bool buttonPress = GUILayout.Button("Fix Now", new GUIStyle("button")
            {
                stretchWidth = false,
                margin = new RectOffset(0, 0, 0, 0),
                padding = new RectOffset(9, 9, 0, 0)
            }, GUILayout.Height(22));
            EditorGUILayout.EndHorizontal();
            GUILayout.EndVertical();
            return buttonPress;
        }
        
        public static void sRGBWarning(MaterialProperty tex)
        {
            if (tex.textureValue)
            {
                string sRGBWarning = "This texture is marked as sRGB, but should not contain color information.";
                string texPath = AssetDatabase.GetAssetPath(tex.textureValue);
                TextureImporter texImporter;
                var importer = TextureImporter.GetAtPath(texPath) as TextureImporter;
                if (importer != null)
                {
                    texImporter = (TextureImporter) importer;
                    if (texImporter.sRGBTexture)
                    {
                        if (TextureImportWarningBox(sRGBWarning))
                        {
                            texImporter.sRGBTexture = false;
                            texImporter.SaveAndReimport();
                        }
                    }
                }
            }
        }
    }
}