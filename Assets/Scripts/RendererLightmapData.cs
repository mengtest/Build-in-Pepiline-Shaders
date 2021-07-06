using UnityEngine;
using System.Collections;
#if UNITY_EDITOR
[ExecuteInEditMode]
#endif
public class RendererLightmapData : MonoBehaviour
{
    [HideInInspector]
    public int lightmapIndex;
    [HideInInspector]
    public Vector4 lightmapScaleOffset;

#if UNITY_EDITOR
    [ExecuteInEditMode]
#endif
    void Start()
    {
        Renderer renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            renderer.lightmapIndex = lightmapIndex;
            renderer.lightmapScaleOffset = lightmapScaleOffset;

        }
    }
}
