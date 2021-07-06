using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthTextureTest : PostEffectsBase
{
	public Shader edgeDetectShader;
	private Material edgeDetectMaterial = null;
	public Material material
	{
		get
		{
			edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
			return edgeDetectMaterial;
		}
	}
	private Camera myCamera;
	public Camera camera
	{
		get
		{
			if (myCamera == null)
			{
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}
	void OnEnable()
	{
		camera.depthTextureMode |= DepthTextureMode.Depth;
	}
	void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (material == null)
		{
			Graphics.Blit(source, destination);
		}
		else
		{
			Graphics.Blit(source, destination, material);
		}
	}
}
