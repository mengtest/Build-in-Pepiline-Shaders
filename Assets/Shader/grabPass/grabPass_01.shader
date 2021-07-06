Shader "Unlit/grabPass_01"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex("BumpTex",2D)="bump"{}
        _BumpScale("BumpScale",Range(1,10)) = 1
        _CubeMap("CubeMap",Cube) = "_SkyBox"{}
        _Distortion("Distortion",Range(0,200)) = 10
        _RefractAmount("RefractAmount",Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent+100"}
        LOD 100
        GrabPass{"_RefractionTex"}
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
     
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
                float4 vertex : SV_POSITION;
                float4 tTW0:TEXCOORD2;
                float4 tTW1:TEXCOORD3;
                float4 tTW2:TEXCOORD4;
                float4 scrPos:TEXCOORD5; 

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpTex;
            float4 _BumpTex_ST;
            float _BumpScale;
            samplerCUBE  _CubeMap;
            float _Distortion;
            float _RefractAmount;
            sampler2D _RefractionTex;//声明
            float4 _RefractionTex_TexelSize;//可获得像素大小

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpTex);
              
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.scrPos = ComputeGrabScreenPos(o.vertex);
    
                float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                float3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent));
                //构建矩阵
                float3 bnormal = normalize(cross(worldNormal,worldTangent));
                //t b n 

                o.tTW0 = float4(worldTangent.x,bnormal.x,worldNormal.x,worldPos.x);
                o.tTW1 = float4(worldTangent.y,bnormal.y,worldNormal.y,worldPos.y);
                o.tTW2 = float4(worldTangent.z,bnormal.z,worldNormal.z,worldPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.tTW0.w, i.tTW1.w, i.tTW2.w);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
        
                float3 nbump;
                nbump.xy = UnpackNormal(tex2D(_BumpTex,i.uv.zw));
                nbump.xy *= _BumpScale;
                nbump.z = sqrt(1.0 - max(0,dot(nbump.xy,nbump.xy)));
                 //转换到世界坐标
                float3 worldNormal = normalize(half3(dot(i.tTW0.xyz,nbump),dot(i.tTW1.xyz,nbump),dot(i.tTW2.xyz,nbump)));

                //偏移算法
                float2 offset = nbump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
                //采样抓屏贴图
                fixed3 refractCol = tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;
                //正常贴图
                fixed4 abedo = tex2D(_MainTex, i.uv.xy);
                //反射
                fixed3 reflectCol = texCUBE(_CubeMap,reflect(-viewDir,worldNormal)).rgb * abedo;
                //玻璃算法
                fixed3 color =  reflectCol * (1-_RefractAmount) + refractCol * _RefractAmount;

                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
