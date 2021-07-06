Shader "Custom/SurfaceStand01"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _SpecColor ("SpecColor", Color) = (1,1,1,1)
        
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Gloss ("Gloss", Range(0,1)) = 0.5
        _Specular ("Specular", Range(0,1)) = 0.0

       _BumpTex ("BumpTex", 2D) = "bump" {}
       _BumpScale("_BumpScale",Range(0,5)) = 1
       _ColorInit("ColorInit",Color)=(1,1,1,1)

       _RimColor("RimColor",Color)=(1,1,1,1)
       _RimPower("RimPower",Range(1,20))=1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM

        #pragma surface surf BlinnPhong fullforwardshadows finalcolor:final

        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D  _BumpTex;
        float _BumpScale;
        fixed4 _ColorInit;
        half _Gloss;
        half _Specular;
        fixed4 _Color;
        fixed4 _RimColor;
        float _RimPower;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpTex;
            float3 viewDir;
            //float3 worldNormal;
        };

       

        UNITY_INSTANCING_BUFFER_START(Props)

        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Specular = _Specular;
            o.Gloss = _Gloss;
            o.Alpha = c.a;
            fixed3 normal = UnpackNormal(tex2D(_BumpTex,IN.uv_BumpTex));
            normal.xy *= _BumpScale;
            o.Normal = normal;

            half rim = 1 - dot(normalize(IN.viewDir),normal);
            float3 rimColor =  _RimColor.rgb * pow(rim,_RimPower);
            o.Emission = rimColor;
        }

        void final(Input IN, SurfaceOutput o, inout fixed4 color)
        {
            color *= _ColorInit;
        }

        ENDCG
    }

    FallBack "Diffuse"
}
