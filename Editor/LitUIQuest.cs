using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;
using z3y.ShaderEditorFunctions;
using static z3y.ShaderEditorFunctions.Functions;

namespace z3y.ShaderEditor
{

    public class SimpleLitGUI : ShaderGUI
    {

        public void ShaderPropertiesGUI(Material material, MaterialProperty[] props, MaterialEditor materialEditor)
        {

            Prop(IfProp("_EnableTextureArray") ? "_MainTexArray" : "_MainTex", "_Color");
            
            Prop("_EnableEmission");

            if(IfProp("_EnableEmission")) Prop("_EmissionMap", "_EmissionColor");

            Prop("_EnableTextureArray");
            if(IfProp("_EnableTextureArray")) Prop("_EnableTextureArrayInstancing");;

            materialEditor.DoubleSidedGIField();
            materialEditor.EnableInstancingField();
            materialEditor.RenderQueueField();
            Prop("_Cull");


            
        }


        private void ApplyChanges()
        {
            SetupGIFlags(GetProperty("_EnableEmission").floatValue, material);
        }

        MaterialEditor materialEditor;
        public bool m_FirstTimeApply = true;

        Material material = null;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            this.materialEditor = materialEditor;
            material = materialEditor.target as Material;

            if (m_FirstTimeApply)
            {
                m_FirstTimeApply = false;
                SetupFoldoutDictionary(material);
                SetupPropertiesDictionary(props);
            }
            
            EditorGUI.BeginChangeCheck();

            ShaderPropertiesGUI(material, props, materialEditor);

            if (EditorGUI.EndChangeCheck()) {
                ApplyChanges();
            };
        }


        // inspector setup
        protected static Dictionary<Material, InspectorData> data = new Dictionary<Material, InspectorData>();

        private void Prop(string property, string extraProperty = null) => MaterialProp(GetProperty(property), extraProperty is null ? null : GetProperty(extraProperty), materialEditor, false, material);
        private void PropTileOffset(string property) => DrawPropTileOffset(GetProperty(property), false, materialEditor, material);
        public float GetFloatValue(string name) => (float)GetProperty(name)?.floatValue;
        public bool IfProp(string name) => GetProperty(name)?.floatValue == 1;

        private void SetupPropertiesDictionary(MaterialProperty[] props)
        {
            data[material].MaterialProperties.Clear();
            for (int i = 0; i < props.Length; i++)
            {
                MaterialProperty p = props[i];
                data[material].MaterialProperties[p.name] = p;
            }
        }

        private MaterialProperty GetProperty(string name)
        {
            data[material].MaterialProperties.TryGetValue(name, out MaterialProperty p);
            return p;
        }

        public void DrawFoldout(string name, Action action, bool defaultValue = false)
        {
            data[material].FoldoutValues.TryGetValue(name, out bool? isOpen);
            bool o = isOpen ?? defaultValue;
            o = Foldout(name, o, action);
            data[material].FoldoutValues[name] = o;
        }
        
        public void DrawTriangleFoldout(string name, Action action, bool defaultValue = false)
        {
            data[material].FoldoutValues.TryGetValue(name, out bool? isOpen);
            bool o = isOpen ?? defaultValue;
            o = TriangleFoldout(o, action);
            data[material].FoldoutValues[name] = o;
        }

        private void SetupFoldoutDictionary(Material material)
        {
            if (data.ContainsKey(material)) return;

            InspectorData toggles = new InspectorData();
            data.Add(material, toggles);
        }
    }
}