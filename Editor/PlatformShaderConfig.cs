using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;


namespace z3y
{
    public class PlatformShaderConfig : EditorWindow
    {
        public static bool isQuest;

        private static Renderer[] _renderers;

     //     public static string[] ShaderKeywordsQuest = {"_NORMALMAP"};
        public static List<string> ShaderKeywordsQuest = new List<string>();

        private static bool normalMapToggleQuest = false;
        private static bool gsaaToggleQuest = false;
        private static bool specularHighlightsToggleQuest = false; //
        private static bool metallicMapToggleQuest = false; // _METALLICGLOSSMAP
        private static bool roughnessMapToggleQuest = false; // _SPECGLOSSMAP
        private static bool occlusionMapToggleQuest = false; // _DETAIL_MULX2
        private static bool reflectionsToggleQuest = false; // _GLOSSYREFLECTIONS_OFF
        
        
            
        
           


        [MenuItem("Window/Shader Config")]
        public static void ShowWindow()
        {
            GetWindow<PlatformShaderConfig>("Shader Config");
        }

        
        static void GlobalKeywordToggle(bool toggle, string keyword)
        {

            _renderers = FindObjectsOfType<Renderer>();
            foreach (var rend in _renderers)
            {
                if (rend.sharedMaterial.shader.name == "VR Standard")
                {
                    VRSShaderEditor.SetMaterialKeywords(rend.sharedMaterial);
                
                    if (toggle) rend.sharedMaterial.EnableKeyword(keyword);
                    else rend.sharedMaterial.DisableKeyword(keyword);
                }
                
            }
        }

        


        private void OnGUI()
        {
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.Space();
            isQuest = EditorGUILayout.Toggle("Preview Quest", isQuest);
            
            
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Quest Shader Features");
            
            normalMapToggleQuest = EditorGUILayout.Toggle("Normal Map", normalMapToggleQuest);
            
            metallicMapToggleQuest = EditorGUILayout.Toggle("Metallic Map", metallicMapToggleQuest);
            roughnessMapToggleQuest = EditorGUILayout.Toggle("Roughness Map", roughnessMapToggleQuest);
            occlusionMapToggleQuest = EditorGUILayout.Toggle("Occlusion Map", occlusionMapToggleQuest);
            
            gsaaToggleQuest = EditorGUILayout.Toggle("GSAA", gsaaToggleQuest);
            reflectionsToggleQuest = EditorGUILayout.Toggle("Reflections", reflectionsToggleQuest);
            specularHighlightsToggleQuest = EditorGUILayout.Toggle("Specular Highlights", specularHighlightsToggleQuest);
            


            if (EditorGUI.EndChangeCheck())
            {
                ApplyChanges();
            }
        }


        public static void ApplyChanges()
        {

            ToggleQuest(normalMapToggleQuest, "_NORMALMAP");
            
            
            
            
            ToggleQuest(metallicMapToggleQuest, "_METALLICGLOSSMAP");
            ToggleQuest(roughnessMapToggleQuest, "_SPECGLOSSMAP");
            ToggleQuest(occlusionMapToggleQuest, "_DETAIL_MULX2");
            ToggleQuest(gsaaToggleQuest, "UNITY_UI_CLIP_RECT");
            ToggleQuest(reflectionsToggleQuest, "_GLOSSYREFLECTIONS_OFF");
            ToggleQuest(specularHighlightsToggleQuest, "_SPECULARHIGHLIGHTS_OFF");
            
            


            //ToggleKeywordS();
            GlobalKeywordToggle(isQuest, "PLATFORM_QUEST");
        }


        private static void ToggleQuest(bool state, string keyword)
        {
            if (state)
            {
                if (!ShaderKeywordsQuest.Contains(keyword)) ShaderKeywordsQuest.Add(keyword);
            }
            else
            {
                if (ShaderKeywordsQuest.Contains(keyword)) ShaderKeywordsQuest.Remove(keyword);
            }
        }

        public static void PlatformCheck()
        {
#if UNITY_ANDROID
            isQuest = true;
#else
            isQuest = false;
#endif

            Debug.Log(Application.platform);
            ApplyChanges();
        }

        private void OnDestroy() => PlatformCheck();
    }


    [InitializeOnLoad]
    public class PlatformCheck
    {
        static PlatformCheck()
        {
            PlatformShaderConfig.PlatformCheck();
        }
    }
}