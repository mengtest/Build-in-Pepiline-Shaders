Shader "Custom/SurfaceStand08"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _NormalTex("NormalTex",2D)="bump"{}
        _NormalScale("NormalScale",float) = 1

        _NoiseTex("NoiseTex",2D) = "white"{}
        _Threshold("Threshold",Range(0,1)) = 1

        _EdgeLength("EdgeLength",Range(0,1)) = 0.1
        _BurnTex("EdgeBurnTex",2D)="white"{}
        _BurnIntensity("BurnIntensity",Range(0,2)) =0.2
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
        float _NormalScale;
        sampler2D _NoiseTex;
        fixed _Threshold;
        fixed _EdgeLength;
        sampler2D _BurnTex;
        fixed _BurnIntensity;
        struct Input
        {
            float2 uv_MainTex;
            float2 uv_NormalTex;
            float2 uv_NoiseTex;
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
            //溶解算法

            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;

            o.Normal = UnpackScaleNormal(tex2D(_NormalTex,IN.uv_NormalTex),_NormalScale);

            fixed noiseVal = tex2D(_NoiseTex,IN.uv_NoiseTex).r;
            clip(noiseVal-_Threshold);

            float edge = saturate((noiseVal-_Threshold)/_EdgeLength);
            fixed4 edgeColor = tex2D(_BurnTex,float2(edge,edge))* (_BurnIntensity * max(0.5,_SinTime.w));
            o.Emission = lerp(edgeColor,fixed4(0,0,0,0),edge).rgb ;


            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
