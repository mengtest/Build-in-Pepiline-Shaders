Shader "Custom/SurfaceStand03"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
      
        _Specular("Specular",2D)="white"{}
        _BumpTex ("BumpTex", 2D) = "bump" {}
        _MaskTex("MaskTex",2D)= "white"{}
        _FireTex("FireTex",2D) = "white" {}

        _FireSpeed("FireSpeed",Vector) =(0,0,0,0)
        _FireIntensity("FireIntensity",Range(1,40)) = 2
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
        sampler2D _Specular;
        sampler2D _BumpTex;
        sampler2D _MaskTex;
        sampler2D _FireTex;
        float4 _FireSpeed;
        float _FireIntensity;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Smoothness;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
            o.Albedo = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Normal = UnpackNormal(tex2D(_BumpTex,IN.uv_MainTex));

            float2 uv = IN.uv_MainTex + _Time.x * _FireSpeed;
            o.Emission = (tex2D(_MaskTex,IN.uv_MainTex) * tex2D(_FireTex,uv) * (_FireIntensity*(_SinTime.w + 1.5))).rgb;
           
            o.Specular = tex2D(_Specular,IN.uv_MainTex).rgb;
            o.Smoothness = _Smoothness;
            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
