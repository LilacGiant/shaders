using UnityEngine;
using UnityEditor;
using System;
using UnityEditor.Build;
using System.Linq;
using System.IO;


namespace z3y
{
    public class SwitchShadersOnPlatformChange : IActiveBuildTargetChanged
    {
        QuestShaderSwitchSettings settingsData = DataManager.Load();

        public int callbackOrder { get { return 33; } }

        public void OnActiveBuildTargetChanged(BuildTarget previousTarget, BuildTarget newTarget)
        {
            if(settingsData.isEnabled)
            {
                if(previousTarget != newTarget && newTarget == BuildTarget.Android)
                {
                    QuestShaderSwitch.SwitchToQuestShaders();
                    Debug.Log("[QuestShaderSwitch] Switched to Quest Shaders");
                }
                else if(previousTarget != newTarget && previousTarget == BuildTarget.Android)
                {
                    QuestShaderSwitch.SwitchToPCShaders();
                    Debug.Log("[QuestShaderSwitch] Switched to PC Shaders");
                }
            }
        }
    }


    public class QuestShaderSwitch : Editor
    {
        const string MaterialTagPC = "QuestShaderSwitch.PC";
        const string MaterialTagQuest = "QuestShaderSwitch.Quest";
        private static readonly string[] allMaterialPaths = AssetDatabase.GetAllAssetPaths().Where(x => x.EndsWith(".mat")).ToArray();

        public static void SwitchToQuestShaders()
        {
            SetPreviousPlatformShaderTag(true);
            SwitchShaders(true);
        }

        public static void SwitchToPCShaders()
        {
            SetPreviousPlatformShaderTag(false);
            SwitchShaders(false);
        }

        private static void SetPreviousPlatformShaderTag(bool isQuest)
        {
            for (int i = 0; i < allMaterialPaths.Length; i++)
            {
                Material material = AssetDatabase.LoadAssetAtPath(allMaterialPaths[i], typeof(Material)) as Material;
                material.SetOverrideTag(!isQuest ? MaterialTagQuest : MaterialTagPC, material.shader.name);
            }

        }

        private static void SwitchShaders(bool isQuest)
        {
            for (int i = 0; i < allMaterialPaths.Length; i++)
            {
                Material material = AssetDatabase.LoadAssetAtPath(allMaterialPaths[i], typeof(Material)) as Material;
                string oldShaderName = material.GetTag(isQuest ? MaterialTagQuest : MaterialTagPC, false);
                if(oldShaderName != "")
                {
                    Shader shader = Shader.Find(oldShaderName);
                    if (shader == null)
                    {
                        Debug.LogError($"[QuestShaderSwitch] Original shader {oldShaderName} for material {material.name} not found");
                    }
                    else
                    {
                        if(material.shader.name != oldShaderName) material.shader = shader;
                    }
                }
            }
        }
    }

    public class QuestShaderSwitchEditorWindow : EditorWindow
    {
        [MenuItem("Window/Quest Shader Switch")]
        public static void ShowWindow()
        {
            GetWindow<QuestShaderSwitchEditorWindow>("Quest Shader Switch");
        }
        public QuestShaderSwitchSettings settingsData;
        bool firstTime = true;
        void OnGUI()
        {
            if (firstTime)
            {
                settingsData = DataManager.Load();
                firstTime = false;
            }
            EditorGUI.BeginChangeCheck();

            settingsData.isEnabled = GUILayout.Toggle(settingsData.isEnabled, "Enable Shader Switch");

            if (EditorGUI.EndChangeCheck())
            {
                DataManager.Save(settingsData);
            }

        }

    }

    [System.Serializable]
    public class QuestShaderSwitchSettings
    {
        public bool isEnabled;
    }

    public static class DataManager
    {
        public static string fileName = Path.Combine(Application.dataPath, "../") + "ProjectSettings/QuestShaderSwitchSettingsData.json";
        public static void Save(QuestShaderSwitchSettings data) => File.WriteAllText(fileName, JsonUtility.ToJson(data));
        public static QuestShaderSwitchSettings Load() => JsonUtility.FromJson<QuestShaderSwitchSettings>(File.ReadAllText(fileName));
    }

    [InitializeOnLoad]
    class Startup
    {
        static Startup()
        {
            if (!File.Exists(DataManager.fileName)) DataManager.Save(new QuestShaderSwitchSettings());
        }
    }



}