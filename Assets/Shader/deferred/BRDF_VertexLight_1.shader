﻿Shader "Unlit/BRDF_VertexLight_1"
{
    Properties
    {
        _Diffuse("_Diffuse",Color)=(1,1,1,1)
        _Specular("_Specular",Color)=(1,1,1,1)
        _Gloss("_Gloss",Range(1,100)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal :NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float3 vertexLight:TEXCOORD2;

            };
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

            #ifdef LIGHTMAP_OFF
                    //求协函数光照
                    float3 shLight = ShadeSH9(float4(v.normal,1.0));
                    o.vertexLight = shLight;
            #ifdef VERTEXLIGHT_ON
                    //顶点光照
                    float3 vertexLight = Shade4PointLights(unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
                        unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,unity_LightColor[3].rgb,
                        unity_4LightAtten0,o.worldPos,o.worldNormal);
                    
                     o.vertexLight  += vertexLight;
            #endif
            #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normalDir = normalize(i.worldNormal);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float3 viewDir =  normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

               float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

               float3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(normalDir,lightDir));

               float3 halfDir = normalize(lightDir+viewDir);

               float3 specualr = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(normalDir,halfDir)),_Gloss);

                return fixed4(ambient+diffuse+specualr+i.vertexLight,1);
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }

            Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal :NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;

                LIGHTING_COORDS(2,3)

            };
            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

               TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normalDir = normalize(i.worldNormal);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float3 viewDir =  normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

               float3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(normalDir,lightDir));

               float3 halfDir = normalize(lightDir+viewDir);

               float3 specualr = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(normalDir,halfDir)),_Gloss);

               fixed atten = LIGHT_ATTENUATION(i);

               return fixed4( (diffuse + specualr)*atten,1);
            }
            ENDCG
        }
    }
}
