Shader "Custom/SurfaceStand05"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalTex("NormalTex",2D) = "bump"{}
        _BurnNormalTex("BurnNormalTex",2D) = "white"{}
        _NormalTill("NormalTill",Range(0,5)) = 1

        _Mask("Mask",2D) = "white"{}
        _BurnTill("BurnTill",Range(1,5)) = 1
        _BurnOffset("BurnOffset",Range(0,10)) = 1
        _BurnRange("BurnRange",Range(0,1)) =0.5
        _BurnColor("BurnColor",Color)=(0,0,0,0)

        //Glow参数
        _GlowColor("GlowColor",Color)=(1,1,1,1)
        _GlowIntensity("GlowIntensity",Range(0,2))=0.5
        _GlowFrequency("GlowFrequency",Range(0,2)) = 0.5
        _GlowOverride("GlowOverride",Range(0,2))=0.5
        _GlowEmission("GlowEmission",Range(0,2))=0.5

        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NormalTex;
        sampler2D _BurnNormalTex;
        sampler2D _Mask;
        
        fixed _NormalTill;
        half _BurnTill;
        half _BurnOffset;
        half _BurnRange;
        fixed4 _BurnColor;

        fixed4 _GlowColor;
        half _GlowIntensity;
        half _GlowFrequency;
        half _GlowOverride;
        half _GlowEmission;

        struct Input
        {
            float2 uv_MainTex;
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
            //正常法线
            float3 normal1 = UnpackNormal(tex2D(_NormalTex,IN.uv_MainTex));

            fixed4 burnNormalTex = tex2D(_BurnNormalTex,IN.uv_MainTex * _NormalTill);
            fixed4 burnNor = fixed4(1,burnNormalTex.g,0,burnNormalTex.r);
            float3 normal2 = UnpackNormal(burnNor);
            float2 maskUv = IN.uv_MainTex * _BurnTill + _BurnOffset * float2(1,1);
            float4 maskColor = tex2D(_Mask,maskUv);
            float maskR = _BurnRange + maskColor.b;

            o.Normal = lerp(normal1,normal2,maskR);
           
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            fixed4 diffuse = lerp(c,_BurnColor,maskR );
            o.Albedo = diffuse.rgb;

            float4 glow = _GlowColor * _GlowIntensity * max(0.5f , sin(_Time.y * _GlowFrequency) + _GlowOverride * burnNormalTex.a);
            //maskColor.r 确定了那个部分烧着，然后burnNormalTex.a 确定了烧着部分那些地方有火焰
            o.Emission = glow * burnNormalTex.a * maskColor.r * _GlowEmission;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }

        ENDCG
    }
    FallBack "Diffuse"
}
