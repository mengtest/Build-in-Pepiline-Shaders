Shader "Custom/SurfaceStand09"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        _NextTex("NextTex",2D) = "white"{}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Dis("Dis",Range(0.1,10)) = 1
        _StartPoint("StartPoint",Range(-10,10)) = 1
        _Tint("Tint",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        float _StartPoint;
        fixed4 _Tint;
        half _Dis;
        sampler2D _NextTex;
        struct Input
        {
            float2 uv_MainTex;
            float2 uv_NextTex;
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            //区域过度算法
            // Albedo comes from a texture tinted by color
            float temp = saturate((IN.worldPos.x + _StartPoint)/_Dis);
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            fixed4 nexC = tex2D(_NextTex,IN.uv_NextTex) * _Tint;

            fixed4 color = lerp(nexC,c,temp);

            o.Albedo = color.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
