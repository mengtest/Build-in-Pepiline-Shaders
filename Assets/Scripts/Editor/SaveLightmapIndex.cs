using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class SaveLightmapIndex 
{
    [MenuItem("Tools/SaveLightmap")]
    static void Setup()
    {
        int count = 0;
        if (Selection.activeTransform != null)
        {

            Renderer[] renderers = Selection.activeTransform.GetComponentsInChildren<Renderer>();
            foreach (var renderer in renderers)
            {
                if (renderer.enabled && (renderer.lightmapIndex == -1 || renderer.lightmapIndex == 65535))
                    continue;

                RendererLightmapData ldata = renderer.gameObject.GetComponent<RendererLightmapData>();
                if (ldata == null)
                    ldata = renderer.gameObject.AddComponent<RendererLightmapData>();
                ldata.lightmapIndex = renderer.lightmapIndex;
                ldata.lightmapScaleOffset = renderer.lightmapScaleOffset;
                ++count;
            }
        }
        Debug.LogFormat("RendererLightmapData: count {0}", count);
    }
}
