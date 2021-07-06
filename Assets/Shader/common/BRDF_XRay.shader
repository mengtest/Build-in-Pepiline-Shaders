Shader "Unlit/BRDF_XRay"
{
    Properties
    {
        _BumpTex("法线贴图",2D)="white"{}
        _BumpScale("_BumpScale",float) = 1

        _RimColor("RimColor",Color) = (1,1,0,1)
		_RimPower ("Rim Power", Range(0.1,8)) = 3.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

         Pass
        {
            Name "XRay"

              //被遮挡后 显示一个外发光
              //外发光需要检测边缘
              //检测边缘：参看视角(V) 和法线（Ｎ）是否垂直 【dot(N,V)= 0 代表垂直】
              // XRay 实现
              ZWrite Off
              Blend SrcAlpha One//混合
              ZTest Greater //被遮挡后才显示

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
                };

                 struct v2f
                {        
                    float4 vertex : SV_POSITION;
                    float3 normal:TEXCOORD0;
                    float3 viewDir:TEXCOORD1;
                };

                fixed4 _RimColor;
                float _RimPower;
                v2f vert (appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);

                    o.normal = v.normal;

                    o.viewDir = ObjSpaceViewDir(v.vertex);

                    return o;
                }

                fixed4 frag (v2f i) : SV_Target
                {
                    float rim = 1.0 - max(0,dot(normalize(i.normal),normalize(i.viewDir)));

                    float4 rimColor  = _RimColor * pow(rim,1/_RimPower);

                    return rimColor;

                }

              ENDCG
        }


        Pass
        {
               Name "XRayNormal"

              //被遮挡后 显示一个外发光
              //外发光需要检测边缘
              //检测边缘：参看视角(V) 和法线（Ｎ）是否垂直 【dot(N,V)= 0 代表垂直】
              // XRay 实现
              Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "LightMode"="ForwardBase"}
              ZTest Greater //被遮挡后才显示
              ZWrite Off

              Blend SrcAlpha One//混合
 
	          LOD 200

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
                    float2 uv : TEXCOORD0;

                    float4 TtW0:TEXCOORD1;
                    float4 TtW1:TEXCOORD2;
                    float4 TtW2:TEXCOORD3;

                };

                sampler2D _BumpTex;
                float4 _BumpTex_ST;
                float _BumpScale;
                fixed4 _RimColor;
                float _RimPower;

                v2f vert (appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    o.uv = TRANSFORM_TEX(v.texcoord,_BumpTex);

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
                    fixed4 albedo_N = tex2D(_BumpTex,i.uv);

                    float3 biNormal;
                    //tangentNobiNormalrmal.xy = albedo_N.xy * 2 -1;
                    biNormal.xy = UnpackNormal(albedo_N);
                    biNormal.xy *= _BumpScale;
                    biNormal.z = sqrt(1.0 - max(0,dot(biNormal.xy, biNormal.xy)));

                    //转换到世界坐标
                    biNormal = normalize(half3(dot(i.TtW0.xyz,biNormal),dot(i.TtW1.xyz,biNormal),dot(i.TtW2.xyz,biNormal)));

                    float rim = 1 - saturate(dot(world_V,biNormal));
                    fixed4 rimColor = _RimColor * pow(rim,_RimPower);

                    return rimColor;
                }

                ENDCG
        }
    }
}
