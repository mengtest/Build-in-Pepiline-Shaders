﻿Shader "Unlit/BRDF_Deferred_1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
         _Diffuse("_Diffuse",Color)=(1,1,1,1)
        _Specular("_Specular",Color)=(1,1,1,1)
        _Gloss("_Gloss",Range(1,50)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="Deferred" }

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UNITY_HDR_ON
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldNormal:TEXCOORD1;
                float3 worldPos:TEXCOORD2;
            };

            struct DeferredOutput
            {
                float4 gBuffer0:SV_TARGET0;
                float4 gBuffer1:SV_TARGET1;
                float4 gBuffer2:SV_TARGET2;
                float4 gBuffer3:SV_TARGET3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            DeferredOutput frag (v2f i)
            {

               DeferredOutput o;
               fixed3 color = tex2D(_MainTex,i.uv) * _Diffuse.rgb;
               o.gBuffer0.rgb = color;
               o.gBuffer0.a = 1;
               o.gBuffer1.rgb = _Specular.rgb;
               o.gBuffer1.a = _Gloss/50.0;
               o.gBuffer2 = fixed4(normalize(i.worldNormal *0.5+0.5),1);

               #if !defined(UNITY_HDR_ON)
                    color.rgb = exp2(-color.rgb);
               #endif
               o.gBuffer3 = fixed4(color,1);
               return o;
            }
            ENDCG
        }
    }
}
