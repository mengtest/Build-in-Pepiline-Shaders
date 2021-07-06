Shader "Unlit/scene_snow_01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex("BumpTex",2D)= "white"{}
        _BumpScale("BumScale",Range(1,10)) = 1
        _BumpSnowTex("_BumpSnowTex",2D)="white"{}
        _BumpSnowScale("BumpSnowScale",Range(1,10)) = 1
        _SnowDir("SnowDir",Vector) =(0,0,0,0)
        _SnowColor("SnowColor",Color)=(1,1,1,1)
        _Snow("Snow",Range(0,1)) = 0.5

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
            #include "Autolight.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal:NORMAL;
                float3 tangent:TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv1 : TEXCOORD0;//maintex and bumptex
                float2 uv2 : TEXCOORD1;//snowtex and snowbump

                float3 worldViewDir:TEXCOORD2;

                float4 TtW0:TEXCOORD3;
                float4 TtW1:TEXCOORD4;
                float4 TtW2:TEXCOORD5;
              
                UNITY_FOG_COORDS(6)//雾
                LIGHTING_COORDS(7,8)//衰减
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            float _BumpScale;
            sampler2D _BumpSnowTex;
            float4 _BumpSnowTex_ST;
            float _BumpSnowScale;
            fixed4 _SnowDir;
            fixed4 _SnowColor;
            fixed _Snow;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv1.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv1.zw = TRANSFORM_TEX(v.texcoord, _BumpTex);
                o.uv2 = TRANSFORM_TEX(v.texcoord, _BumpSnowTex);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir(worldPos);

                float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                float3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent));
                //构建矩阵
                float3 bnormal = normalize(cross(worldNormal,worldTangent));
                //float3x3[t b n ]
                o.TtW0 = float4(worldTangent.x,bnormal.x,worldNormal.x,worldPos.x);
                o.TtW1 = float4(worldTangent.y,bnormal.y,worldNormal.y,worldPos.y);
                o.TtW2 = float4(worldTangent.z,bnormal.z,worldNormal.z,worldPos.z);

               UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.worldViewDir);
                float3 worldPos = float3(i.TtW0.w,i.TtW1.w,i.TtW2.w);
                float3 lightdir = normalize(UnityWorldSpaceLightDir(worldPos));
                float3 worldNormal = normalize(float3(i.TtW0.z,i.TtW1.z,i.TtW2.z));
                //主帖图法线
                float4 abedoN = tex2D(_BumpTex,i.uv1.zw);
                half3 bnormal;
                bnormal = UnpackNormal(abedoN);
                bnormal.xy *= _BumpScale;
                bnormal.z = sqrt(1.0 - saturate(dot( bnormal.xy, bnormal.xy)));

                float3 tnormal = half3(dot(i.TtW0,bnormal),dot(i.TtW1,bnormal),dot(i.TtW2,bnormal));
                tnormal = normalize(tnormal);
                //主帖图
                float3 abedoT = tex2D(_MainTex,i.uv1.xy).rgb;
    
                //雪的法线
                abedoN = tex2D(_BumpSnowTex,i.uv1.zw);
                half3 bnormal2 = UnpackNormal(abedoN);
                bnormal2.xy *= _BumpSnowScale;
                bnormal2.z = sqrt(1.0 - saturate(dot( bnormal2.xy, bnormal2.xy)));

                float3 adedo = abedoT;
                float3 wnormal = bnormal;
                if(dot(_SnowDir.xyz,worldNormal) > lerp(1,-1,_Snow))
                {
                     adedo = _SnowColor.rgb *2;
                     wnormal = bnormal2;
                }
          
                float3 diffuseColor = _LightColor0.rgb * adedo * saturate(dot(wnormal,lightdir));

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed4 col = fixed4(ambient + diffuseColor,1);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
