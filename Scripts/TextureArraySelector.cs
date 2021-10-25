using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class TextureArraySelector : MonoBehaviour
{
    [Range(0, 64)][SerializeField] private int index = 0;

    private void OnValidate()
    {
        List<Vector3> uvs = new List<Vector3>();
        var mesh = this.GetComponent<MeshFilter>().sharedMesh;
        mesh.GetUVs(0, uvs);
        for (int i = 0; i < uvs.Count; i++)
        {
            uvs[i] = new Vector3(uvs[i].x, uvs[i].y, index);
        }
        mesh.SetUVs(0, uvs);
    }
}
