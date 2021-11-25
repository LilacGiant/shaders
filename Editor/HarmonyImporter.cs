#if !HARMONY_INCLUDED
using UnityEditor;

public class HarmonyImporter
{
    const string unityPackagePath = "Assets/Shaders/z3y/Harmony/Import0Harmony.unitypackage";

    [InitializeOnLoadMethod]
    static void ImportHarmonyIfDoesntExists()
    {
        var searchGUIDs = AssetDatabase.FindAssets("0Harmony");

        bool harmonyExists = false;
        for (int i = 0; i < searchGUIDs.Length; i++)
        {
            string path = AssetDatabase.GUIDToAssetPath(searchGUIDs[i]);
            bool isDLL = System.IO.Path.GetExtension(path) == ".dll";
            if(isDLL) harmonyExists = true;
        }

        if(!harmonyExists) AssetDatabase.ImportPackage(unityPackagePath, false);

        string defines = PlayerSettings.GetScriptingDefineSymbolsForGroup(BuildTargetGroup.Standalone);
        defines += ";HARMONY_INCLUDED";
        PlayerSettings.SetScriptingDefineSymbolsForGroup(BuildTargetGroup.Standalone, defines);
    }
}
#endif