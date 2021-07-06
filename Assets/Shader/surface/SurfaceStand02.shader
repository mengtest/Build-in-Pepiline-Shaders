Shader "Custom/SurfaceStand02"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _SpecColor ("SpecColor", Color) = (1,1,1,1)
        
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Gloss ("Gloss", Range(0,50)) = 0.5
        _Specular ("Specular", Range(0,1)) = 0.0

       _BumpTex ("BumpTex", 2D) = "bump" {}
       _BumpScale("_BumpScale",Range(0,5)) = 1
       _ColorInit("Init",Color)=(1,1,1,1)

       _RimColor("RimColor",Color)=(1,1,1,1)
       _RimPower("RimPower",Range(0,3))=1

       _Steps("Steps",Range(0,4)) = 30
       _ToonEffect("ToonEffect",Range(0,1)) = 0.5

        _OutLine("OutLine",Color)=(1,1,1,1)
        _line("line",Range(0.0001,1)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        UsePass "Unlit/BRDF_Outline/Outline"

        UsePass "Unlit/BRDF_XRay/XRay"

        CGPROGRAM

        #pragma surface surf Toon fullforwardshadows finalcolor:final

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
        fixed _Steps;
        fixed _ToonEffect;

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

            if (_RimPower > 0)
            {
                half rim = 1 - dot(normalize(IN.viewDir),normal);
                float3 rimColor =  _RimColor.rgb * pow(rim,_RimPower);
                o.Emission = rimColor;
            }
        }

        void final(Input IN, SurfaceOutput o, inout fixed4 color)
        {
            color *= _ColorInit;
        }

        half4 LightingToon (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
        {
             float difLight = dot(lightDir,s.Normal) * 0.5 + 0.5;
             difLight = smoothstep(0,1,difLight);
             
             float toon = floor(difLight * _Steps)/_Steps;

             difLight = lerp(difLight,toon,_ToonEffect);

             float3 diffuse = _LightColor0 * s.Albedo * difLight;

             float3 halfDir = normalize(viewDir+lightDir);
             float3 specular = _LightColor0.rgb * _SpecColor.rgb * pow(max(0,dot(s.Normal,halfDir)),_Gloss);


             return half4(diffuse + specular,1);
        }

        ENDCG
    }

    FallBack "Diffuse"
}
