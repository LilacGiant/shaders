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
    }

    public class ShaderEditor : ShaderGUI
    {
        protected static Dictionary<Material, FoldoutToggles> Foldouts = new Dictionary<Material, FoldoutToggles>();
        protected BindingFlags bindingFlags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static;

        //Assign all properties as null at first to stop hundreds of warnings spamming the log when script gets compiled.
        //If they aren't we get warnings, because assigning with reflection seems to make Unity think that the properties never actually get used.
        protected MaterialProperty _MainTex = null;
        protected MaterialProperty _Color = null;
        


        MaterialEditor m_MaterialEditor;
        bool m_FirstTimeApply = true;

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
                m_FirstTimeApply = false;
            }

            ShaderPropertiesGUI(material);
        }

        public void ShaderPropertiesGUI(Material material)
        {
            // Use default labelWidth
            EditorGUIUtility.labelWidth = 0f;

            // Detect any changes to the material
            EditorGUI.BeginChangeCheck();
            {
                Foldouts[material].ShowSurfaceInputs = LitStyles.ShurikenFoldout("Surface Inputs", Foldouts[material].ShowSurfaceInputs);
                if(Foldouts[material].ShowSurfaceInputs)
                {
                    EditorGUI.indentLevel++;
                    m_MaterialEditor.TexturePropertySingleLine(new GUIContent("Base Map", "RGBA"), _MainTex, _Color);
                    Foldouts[material].Show_MainTex = LitStyles.TextureFoldout(Foldouts[material].Show_MainTex);
                    if(Foldouts[material].Show_MainTex){
                        m_MaterialEditor.TextureScaleOffsetProperty(_MainTex);
                    }
                    
                }
                
            }


            Foldouts[material].ShowAdvanced = LitStyles.ShurikenFoldout("Advanced Options", Foldouts[material].ShowAdvanced);
            if(Foldouts[material].ShowAdvanced)
                {
                    m_MaterialEditor.EnableInstancingField();
                    m_MaterialEditor.DoubleSidedGIField();
                }
        }

        private void SetupFoldoutDictionary(Material material)
        {
            if (Foldouts.ContainsKey(material))
                return;

            FoldoutToggles toggles = new FoldoutToggles();
            Foldouts.Add(material, toggles);
        }
    }
}