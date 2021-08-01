using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;

namespace Lit
{
    [InitializeOnLoad]
    public class LitStyles : MonoBehaviour
    {

        public static bool TextureFoldout(bool display)
        {
            var rect = GUILayoutUtility.GetRect(16f, 0);
            var e = Event.current;
            var toggleRect = new Rect(rect.x, rect.y - 20f, 13f, 13f);
            if (e.type == EventType.Repaint)
            {
                EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
            }
            if (e.type == EventType.MouseDown && toggleRect.Contains(e.mousePosition))
            {
                display = !display;
                e.Use();
            }
            return display;
        }

        public static bool ShurikenFoldout(string title, bool display)
        {
            var rect = DrawShuriken(title, new Vector2(20f, -2f), 22);
            var e = Event.current;
            var toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
            if (e.type == EventType.Repaint)
            {
                EditorStyles.foldout.Draw(toggleRect, false, false, display, false);
            }
            if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
            {
                display = !display;
                e.Use();
            }
            return display;
        }

        private static Rect DrawShuriken(string title, Vector2 contentOffset, int HeaderHeight)
        {
            var style = new GUIStyle("ShurikenModuleTitle");
            style.font = new GUIStyle(EditorStyles.boldLabel).font;
            style.fontSize = GUI.skin.font.fontSize;
            style.border = new RectOffset(15, 7, 4, 4);
            style.fixedHeight = HeaderHeight;
            style.contentOffset = contentOffset;
            var rect = GUILayoutUtility.GetRect(16f, HeaderHeight, style);

            GUI.Box(rect, title, style);
            return rect;
        }


    }
}

