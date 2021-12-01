using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;
using z3y.ShaderEditorFunctions;
using static z3y.ShaderEditorFunctions.Functions;

namespace z3y.ShaderEditor
{

    public class LitFallbackUI : ShaderGUI
    {

        public void ShaderPropertiesGUI(Material material, MaterialProperty[] props, MaterialEditor materialEditor)
        {
            
            Prop("_Mode");
            EditorGUILayout.Space();

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


        private void ApplyChanges(Material material, MaterialProperty[] props, MaterialEditor materialEditor)
        {
            // SetupGIFlags(GetProperty("_EnableEmission").floatValue, material);
            foreach(Material m in materialEditor.targets)
            {
                SetupMaterialWithBlendMode(m, (int)GetProperty("_Mode").floatValue);
            }
        }

        MaterialEditor materialEditor;
        public bool m_FirstTimeApply = true;

        Material material = null;
        MaterialProperty[] allProps = null;
        
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            this.materialEditor = materialEditor;
            material = materialEditor.target as Material;
            allProps = props;

            if (m_FirstTimeApply)
            {
                m_FirstTimeApply = false;
                SetupFoldoutDictionary(material);
                // SetupPropertiesDictionary(props);
                ApplyChanges(material, props, materialEditor);
            }
            
            EditorGUI.BeginChangeCheck();

            ShaderPropertiesGUI(material, props, materialEditor);

            if (EditorGUI.EndChangeCheck()) {
                ApplyChanges(material, props, materialEditor);
            };
        }
        
        public static void SetupMaterialWithBlendMode(Material material, int type)
        {
            switch (type)
            {
                case 0:
                    material.SetOverrideTag("RenderType", "");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.renderQueue = -1;
                    break;
                case 1:
                case 3:
                case 2:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
            }
        }


        // inspector setup
        protected static Dictionary<Material, InspectorData> data = new Dictionary<Material, InspectorData>();

        private void Prop(string property, string extraProperty = null) => MaterialProp(GetProperty(property), extraProperty is null ? null : GetProperty(extraProperty), materialEditor, false, material);
        private void PropTileOffset(string property) => DrawPropTileOffset(GetProperty(property), false, materialEditor, material);
        public float GetFloatValue(string name) => (float)GetProperty(name)?.floatValue;
        public bool IfProp(string name) => GetProperty(name)?.floatValue == 1;
        

        private MaterialProperty GetProperty(string name)
        {
            MaterialProperty p = System.Array.Find(allProps, x => x.name == name);
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