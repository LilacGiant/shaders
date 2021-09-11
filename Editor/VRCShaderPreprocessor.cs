// remove unneeded postprocessing shaders, deferred pass and forwardadd or shadowcaster pass from vrchat worlds
#if UNITY_EDITOR
#if VRC_SDK_VRCSDK2 || VRC_SDK_VRCSDK3
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;
using System;

namespace z3y
{
    public class VRCShaderPreprocessor : IPreprocessShaders
    {

        public int callbackOrder { get { return 3; } }

        SettingsData settingsData = DataManager.Load();

        public void OnProcessShader(Shader shader, ShaderSnippetData snippet, IList<ShaderCompilerData> data)
        {
            bool shouldStrip = false;
            

            if (shader.name.StartsWith("Hidden/PostProcessing/")) shouldStrip = true;

            if (snippet.passType == PassType.Deferred || snippet.passType == PassType.LightPrePassBase || snippet.passType == PassType.LightPrePassFinal || snippet.passType == PassType.Meta) shouldStrip = true;

            if (settingsData.RemoveAddPass && snippet.passType == PassType.ForwardAdd) shouldStrip = true;

            if (settingsData.RemoveShadowcaster && snippet.passType == PassType.ShadowCaster) shouldStrip = true;

            for (int i = data.Count - 1; i >= 0; --i)
            {
                if (shouldStrip) data.RemoveAt(i);
            }
        }
    }

    public class VRCShaderPreprocessorEditor : EditorWindow
    {
        [MenuItem("Tools/VRCShaderPreprocessor")]
        public static void ShowWindow()
        {
            GetWindow<VRCShaderPreprocessorEditor>("VRCShaderPreprocessor");
        }
        public SettingsData settingsData;
        bool firstTime = true;
        private void OnGUI()
        {
            if (firstTime)
            {
                settingsData = DataManager.Load();
                firstTime = false;
            }
            EditorGUI.BeginChangeCheck();

            settingsData.RemoveAddPass = GUILayout.Toggle(settingsData.RemoveAddPass, "Remove ForwardAdd Pass");
            settingsData.RemoveShadowcaster = GUILayout.Toggle(settingsData.RemoveShadowcaster, "Remove Shadowcaster Pass");

            if (EditorGUI.EndChangeCheck())
            {
                DataManager.Save(settingsData);
            }
        }


    }


    [System.Serializable]
    public class SettingsData
    {
        public bool RemoveAddPass;
        public bool RemoveShadowcaster;
    }

    public static class DataManager
    {
        public static string fileName = Path.Combine(Application.dataPath, "../") + "ProjectSettings/VRCShaderPreprocessorData.json";
        public static void Save(SettingsData data) => File.WriteAllText(fileName, JsonUtility.ToJson(data));
        public static SettingsData Load() => JsonUtility.FromJson<SettingsData>(File.ReadAllText(fileName));
    }

    [InitializeOnLoad]
    class Startup
    {
        static Startup()
        {
            if (!File.Exists(DataManager.fileName)) DataManager.Save(new SettingsData());
        }
    }
}
#endif
#endif