Shader "ASGame/BRDF_XRAY_NPC"
{
    //在世界空间计算光照模型
    Properties
    {
        _MainTex ("主帖图", 2D) = "white" {}
        _Color_Dif("Color InIt",Color) = (1,1,1,1)
        _Gloss("高光范围",Range(1.0,256)) = 8
        _Color_Specu("Color Specular",Color) = (1,1,1,1)

        _BumpTex("法线贴图",2D)="white"{}
        _BumpScale("_BumpScale",float) = 1

        _RimColor("RimColor",Color) = (1,1,0,1)
		_RimPower ("Rim Power", Range(0.1,8)) = 3.0

    }

    SubShader
    {
       
       UsePass "Unlit/BRDF_XRay/XRayNormal"

        Pass
        {
            //正常光照
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
                float2 texcoord : TEXCOORD0;
                float4 tangent:TANGENT;//切线
            };

            struct v2f
            {        
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;

                float4 TtW0:TEXCOORD1;
                float4 TtW1:TEXCOORD2;
                float4 TtW2:TEXCOORD3;

            };

            fixed4 _Color_Dif;
            fixed4 _Color_Specu;
            float _Gloss;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            float _BumpScale;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpTex);

               float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                float3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent));
                float3 worldNormal = normalize(UnityObjectToWorldDir(v.normal));
                float3 worldBinormal = cross(worldNormal,worldTangent);

                //构建一个转换矩阵
                o.TtW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //需要 V I H N
                float3 worldPos = float3(i.TtW0.z,i.TtW1.z,i.TtW2.z);
                float3 world_V = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 world_I = normalize(UnityWorldSpaceLightDir(worldPos));

               // float3 N = normalize(i.worldNormal);  
                fixed4 albedo_N = tex2D(_BumpTex,i.uv.zw);

                float3 biNormal;
                //tangentNobiNormalrmal.xy = albedo_N.xy * 2 -1;
                biNormal.xy = UnpackNormal(albedo_N);
                biNormal.xy *= _BumpScale;
                biNormal.z = sqrt(1.0 - max(0,dot(biNormal.xy, biNormal.xy)));

                //转换到世界坐标
                biNormal = normalize(half3(dot(i.TtW0.xyz,biNormal),dot(i.TtW1.xyz,biNormal),dot(i.TtW2.xyz,biNormal)));

                //纹理采样
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color_Dif.rgb;

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //漫反射
                float3 diffuse = _LightColor0.rgb * albedo * max(0,dot(biNormal,world_I));

                //高光反射
                float3 H = normalize(world_V + world_I);

                float3 specular = _LightColor0.rgb * _Color_Specu * pow(max(0,dot(H,biNormal)),_Gloss);

                float3 col = ambient + diffuse + specular;
 
                return float4(col,1.0);
            }
            ENDCG
        }
    }
}
