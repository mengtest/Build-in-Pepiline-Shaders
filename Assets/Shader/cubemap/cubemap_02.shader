Shader "Unlit/cubemap_02"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecularColor("SpecularColor",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(0,40))= 1
        _BumpTex("BumpTex",2D)="bump"{}
        _CubeMap("CubeMap",Cube) = "_SkyBox"{}
        _RefractionColor("RefractionColor",Color) = (1,1,1,1)
        _RefractionAmount("RefractionAmount",Range(0,1)) = 0.5
        _RefractionRatio("RefractionRatio",Range(0,2)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "autolight.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal:NORMAL;
                float3 tangent:TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;

                float3 worldViewDir :TEXCOORD2;

                float4 tTW0:TEXCOORD3;
                float4 tTW1:TEXCOORD4;
                float4 tTW2:TEXCOORD5;

                float3 worldRefra:TEXCOORD6;

                LIGHTING_COORDS(7,8)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            samplerCUBE  _CubeMap;
            fixed4 _RefractionColor;
            fixed _RefractionAmount;
            fixed4 _SpecularColor;
            float _Gloss;
            fixed _RefractionRatio;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

               float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
               o.worldViewDir = UnityWorldSpaceViewDir(worldPos);

               float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
               float3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent));
               //构建矩阵
               float3 bnormal = normalize(cross(worldNormal,worldTangent));
               //t b n 

               o.tTW0 = float4(worldTangent.x,bnormal.x,worldNormal.x,worldPos.x);
               o.tTW1 = float4(worldTangent.y,bnormal.y,worldNormal.y,worldPos.y);
               o.tTW2 = float4(worldTangent.z,bnormal.z,worldNormal.z,worldPos.z);

               //折射
               o.worldRefra = refract(-normalize(o.worldViewDir),worldNormal,_RefractionRatio);

               TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //float3 worldNormal = float3(o.tTW0.z,o.tTW1.z,o.tTW2.z);
                float3 worldPos = float3(i.tTW0.w,i.tTW1.w,i.tTW2.w);
                float3 worldLightdir = normalize(UnityWorldSpaceLightDir(worldPos));
                float3 worldViewdir = normalize(i.worldViewDir);

                float4 albedoN = tex2D(_BumpTex,i.uv.zw);
                float3 nbump;
                nbump.xy = UnpackNormal(albedoN);
                nbump.z = sqrt(1.0 - max(0,dot(nbump.xy,nbump.xy)));
                 //转换到世界坐标
                float3 worldNormal = normalize(half3(dot(i.tTW0.xyz,nbump),dot(i.tTW1.xyz,nbump),dot(i.tTW2.xyz,nbump)));

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffColor = _LightColor0.rgb * tex2D(_MainTex, i.uv.xy).rgb * saturate(dot(worldNormal,worldLightdir));
                fixed3 refraction = texCUBE(_CubeMap,i.worldRefra).rgb * _RefractionColor;

                fixed3 diffuse = lerp(diffColor,refraction,_RefractionAmount);

                float3 halfDir = normalize(worldViewdir + worldLightdir);
                fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);

                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                fixed3 color = ambient + (refraction + specular) * atten;

                UNITY_APPLY_FOG(i.fogCoord, color);

                return fixed4(color,1);
            }
            ENDCG
        }
    }

    Fallback "VertexLit"
}
