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
                    QuestShaderSwitch.TogglePlatformShaders();
                    Debug.Log("[QuestShaderSwitch] Switched to Quest Shaders");
                }
                else if(previousTarget != newTarget && previousTarget == BuildTarget.Android)
                {
                    QuestShaderSwitch.TogglePlatformShaders();
                    Debug.Log("[QuestShaderSwitch] Switched to PC Shaders");
                }
            }
        }
    }


    public class QuestShaderSwitch : Editor
    {
        const string MaterialTag = "QuestShaderSwitch.Shader";
        private static readonly string[] allMaterialPaths = AssetDatabase.GetAllAssetPaths().Where(x => x.EndsWith(".mat")).ToArray();

        public static void TogglePlatformShaders()
        {
            for (int i = 0; i < allMaterialPaths.Length; i++)
            {
                Material material = AssetDatabase.LoadAssetAtPath(allMaterialPaths[i], typeof(Material)) as Material;
                string oldShaderName = material.GetTag(MaterialTag, false);
                material.SetOverrideTag(MaterialTag, material.shader.name);

                if(oldShaderName != "")
                {
                    Shader shader = Shader.Find(oldShaderName);
                    if (shader == null)
                    {
                        Debug.LogError($"[QuestShaderSwitch] Original shader {oldShaderName} for material {material.name} not found");
                    }
                    if(material.shader.name != oldShaderName) material.shader = shader;
                }
            }
        }

        public static void ClearAllData()
        {
            for (int i = 0; i < allMaterialPaths.Length; i++)
            {
                Material material = AssetDatabase.LoadAssetAtPath(allMaterialPaths[i], typeof(Material)) as Material;
                material.SetOverrideTag(MaterialTag, "");
            }
        }
    }

    public class QuestShaderSwitchEditorWindow : EditorWindow
    {
        [MenuItem("Window/Quest Shader Switch", false, 100)]
        public static void ShowWindow()
        {
            GetWindow<QuestShaderSwitchEditorWindow>("Quest Shader Switch");
        }
        public QuestShaderSwitchSettings settingsData;
        bool firstTime = true;
        private bool toggleShadersSwitch;
        bool isQuest;

        private void OnGUI()
        {
            if (firstTime)
            {
                isQuest = Application.platform == RuntimePlatform.Android;
                settingsData = DataManager.Load();
                firstTime = false;
            }
            EditorGUI.BeginChangeCheck();

            settingsData.isEnabled = EditorGUILayout.ToggleLeft("Enable Shader Switch On Platform Change", settingsData.isEnabled);
            EditorGUI.BeginDisabledGroup(!settingsData.isEnabled);


            if(toggleShadersSwitch = EditorGUILayout.ToggleLeft("Preview " + (isQuest ? "PC" : "Quest") + " Shaders", toggleShadersSwitch))
            {
                QuestShaderSwitch.TogglePlatformShaders();
            }

            EditorGUILayout.Space(20);

            if(GUILayout.Button("Clear All Data"))
            {
                if(EditorUtility.DisplayDialog("Clear All Data", "Clear all fallback shaders for materials in project and keep current ones", "Clear" ,"NO"))
                {
                    QuestShaderSwitch.ClearAllData();
                }
            }
            


            EditorGUI.EndDisabledGroup();
            if (EditorGUI.EndChangeCheck())
            {
                DataManager.Save(settingsData);
            }
        }

    }

    [System.Serializable]
    public class QuestShaderSwitchSettings
    {
        public bool isEnabled = false;
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