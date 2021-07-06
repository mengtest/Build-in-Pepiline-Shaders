Shader "Unlit/BRDF_Shadow"
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
                float4 pos : SV_POSITION;
                float3 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float3 vertexLight:TEXCOORD2;
                //SHADOW_COORDS(3) //仅仅是阴影
                LIGHTING_COORDS(3,4)//
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
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
                
                TRANSFER_SHADOW(o);
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

               //fixed shadow = SHADOW_ATTENUATION(i);
               //这个函数包含了光照衰减和阴影
               //因为ForwardBase逐像素光影一般是方向光，衰减为1，atten在这里实际是阴影值
               UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
               return fixed4(ambient + (diffuse + specualr)*atten + i.vertexLight,1);
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
            #pragma multi_compile_fwdadd_fullshadows

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
                LIGHTING_COORDS(2,3)//包含光照衰减以及阴影


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

              //fixed atten = LIGHT_ATTENUATION(i);
              //包含光照衰减以及阴影
               UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
               return fixed4( (diffuse + specualr)*atten,1);
            }
            ENDCG
        }


        Pass 
        {
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
            #include "UnityCG.cginc"

            struct v2f {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert( appdata_base v )
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }

    //FallBack "Diffuse"

    
}
