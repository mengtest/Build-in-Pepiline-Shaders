Shader "Custom/SurfaceStand10"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        
        _BumpTex("BumTex",2D)="bump"{}
        _SnowDir("SnowDir",Vector)=(0,0,0,0)
        _SnowTex("SnowTex",2D)= "white" {}
        _SnowAmount("SnowAmount",Range(0,2)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardSpecular fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _BumpTex;
        sampler2D _SnowTex;
        half3 _SnowDir;
        fixed _SnowAmount;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpTex;
            float2 uv_SnowTex;
            float3 worldNormal;
            INTERNAL_DATA
        };

        half _Glossiness;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            //雪效果 顶点法线与雪方向点击
            float3 bumpTex = UnpackNormal(tex2D(_BumpTex,IN.uv_BumpTex));
            o.Normal = bumpTex;
            //法线贴图世界空间位置
            fixed3 wNormal = WorldNormalVector(IN,bumpTex);

            float lerpVal = saturate(dot(_SnowDir.xyz,wNormal));

            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            fixed4 snowColor = tex2D(_SnowTex,IN.uv_SnowTex) * _SnowAmount;

            o.Albedo = lerp(snowColor,c,lerpVal).rgb;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
