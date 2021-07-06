Shader "Custom/SurfaceStand07"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Blursize("Blursize",Range(0,0.1)) = 0
        [Toggle]_ToggleBlur("ToggleBlur",Range(0,1)) = 0
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
        fixed _Blursize;
        fixed _ToggleBlur;
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
            //模糊算法
            //偏移采样3次
            fixed4 offset1 = tex2D(_MainTex,IN.uv_MainTex + float2(0,_Blursize));
            fixed4 offset2 = tex2D(_MainTex,IN.uv_MainTex + float2(_Blursize,0));
            fixed4 offset3 = tex2D(_MainTex,IN.uv_MainTex + float2(_Blursize,_Blursize));

            // Albedo comes from a texture tinted by color
               fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            if(_ToggleBlur > 0)
            {
             
                fixed4 offsetColor = c * 0.4 + offset1*0.2 + offset2*0.2 + offset3*0.2;
                o.Albedo = offsetColor.rgb;
            }
            else
            {
                  o.Albedo = c.rgb;
            }
           
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
