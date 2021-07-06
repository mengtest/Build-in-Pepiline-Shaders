Shader "Custom/wetGrass"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalTex("NormalTex",2D)="bump"{}
        _NormalScale("NormalScale",float) = 1
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _WetColor("WetColor",Color)=(1,1,1,1)
        _WetMapTex("WetMapTex",2D)="white"{}

        _WetGlossiness ("WetGlossiness", Range(0,1)) = 0.5
        _WetMetallic ("WetMetallic", Range(0,1)) = 0.0
        _Wetness("Wetness",Range(0,1))=0.0

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
        sampler2D _NormalTex;
        sampler2D _WetMapTex;
        struct Input
        {
            float2 uv_MainTex;
            float2 uv_WetMapTex;
            float2 uv_NormalTex;

        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _WetColor;
        half _WetGlossiness;
        half _WetMetallic;
        half _Wetness;
        float _NormalScale;
        UNITY_INSTANCING_BUFFER_START(Props)

        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed wetness = tex2D(_WetMapTex,IN.uv_WetMapTex).r * _Wetness;
        
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * lerp(_Color,_WetColor,wetness);
            o.Albedo = c.rgb;

            o.Normal = lerp(UnpackScaleNormal(tex2D(_NormalTex,IN.uv_NormalTex),_NormalScale),half3(0,0,1),wetness);
            o.Metallic = lerp(_Metallic,_WetMetallic,wetness);
            o.Smoothness = lerp(_WetGlossiness,_Glossiness,wetness);
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
