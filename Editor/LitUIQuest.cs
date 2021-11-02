using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;
using System.Reflection;

namespace z3y
{
    
    public class LitUIQuest : ShaderGUI
    {
        protected MaterialProperty _MainTex = null;
        protected MaterialProperty _Color = null;
        protected MaterialProperty _EnableEmission = null;
        protected MaterialProperty _EmissionColor = null;
        protected MaterialProperty _EmissionMap = null;
        protected MaterialProperty _Cull = null;
        protected MaterialProperty _MainTexArray = null;
        protected MaterialProperty _EnableTextureArray = null;
        protected MaterialProperty _TextureIndex = null;
        protected MaterialProperty _EnableTextureArrayInstancing = null;

        public void ShaderPropertiesGUI(Material material)
        {
            if(_EnableTextureArray.floatValue == 0)
            {
                me.TexturePropertySingleLine(new GUIContent(_MainTex.displayName), _MainTex, _Color);
            }
            else
            {
                // if(material.enableInstancing) me.ShaderProperty(_TextureIndex, _TextureIndex.displayName);
                me.TexturePropertySingleLine(new GUIContent(_MainTexArray.displayName), _MainTexArray, _Color);
            }

            me.ShaderProperty(_EnableEmission, _EnableEmission.displayName);

            if(_EnableEmission.floatValue == 1)
            {
                me.TexturePropertySingleLine(new GUIContent(_EmissionMap.displayName), _EmissionMap, _EmissionColor);
            }

            me.ShaderProperty(_EnableTextureArray, _EnableTextureArray.displayName);
            if(_EnableTextureArray.floatValue == 1) me.ShaderProperty(_EnableTextureArrayInstancing, _EnableTextureArrayInstancing.displayName);

            me.DoubleSidedGIField();
            me.EnableInstancingField();
            me.RenderQueueField();
            me.ShaderProperty(_Cull, _Cull.displayName);
            
        }

        protected static Dictionary<Material, LitFoldouts> md = new Dictionary<Material, LitFoldouts>();
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
            allProps = props;

            if (m_FirstTimeApply)
            {
                m_FirstTimeApply = false;
            }
            
            EditorGUI.BeginChangeCheck();
            EditorGUI.indentLevel++;

            ShaderPropertiesGUI(material);
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