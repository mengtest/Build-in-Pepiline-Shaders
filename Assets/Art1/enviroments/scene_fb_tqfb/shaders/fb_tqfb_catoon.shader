Shader "Unlit/fb_tqfb_catoon"
{
    //渐变纹理实现的 卡通猫
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse("_Diffuse",Color) = (1,1,1,1)

        _NormalTex("NormalTex",2D) = "white"{}
        _BumpScale("BumpScale",Range(0,5)) = 1

        _MaskTex("MaskTex", 2D) = "white" {}
        _MaskScale("MaskScale",Range(0,100)) = 1

        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(0,50)) = 1

        //_RanmpTex("RanmpTex",2D) = "white"{}
         _Steps("_Steps",Range(1,30)) = 1
        _ToonEffect("_ToonEffect",Range(0,1)) = 0.5

        _OutLine("OutLine",Color)=(1,1,1,1)
        _line("line",Range(0.0001,1)) = 0.01

         _RimColor("_RimColor",Color)=(1,1,1,1)
        _RimPower("_RimPower",Range(0,4)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        UsePass "Unlit/BRDF_Outline/Outline"

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 tangent :TANGENT;
                float4 texcoord : TEXCOORD0;
                
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 uv2: TEXCOORD1;

                float4 tTW0:TEXCOORD2;
                float4 tTW1:TEXCOORD3;
                float4 tTW2:TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            //sampler2D _RanmpTex;
            //float4 _RanmpTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            float _BumpScale;
            float _MaskScale;
            float _Steps;
            float _ToonEffect;

            fixed4 _RimColor;
            float _RimPower;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NormalTex);
                o.uv2.xy =  TRANSFORM_TEX(v.texcoord, _MaskTex);
                //o.uv2.zw =  TRANSFORM_TEX(v.texcoord, _RanmpTex);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                //构建(切线--转换)到世界空间的矩阵

                float3 wnormal = normalize(UnityObjectToWorldDir(v.normal));
                float3 wtangent = normalize(UnityObjectToWorldDir(v.tangent));
                
                float3 binormal = cross(wnormal,wtangent);

                o.tTW0 = float4(wtangent.x,binormal.x,wnormal.x,worldPos.x);
                o.tTW1 = float4(wtangent.y,binormal.y,wnormal.y,worldPos.y);
                o.tTW2 = float4(wtangent.z,binormal.z,wnormal.z,worldPos.z);


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // N V I H

                float3 worldPos = float3(i.tTW0.w,i.tTW1.w,i.tTW2.w);
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                //法线
                fixed4 normal_albedo = tex2D(_NormalTex, i.uv.zw);
                float3 biNormal;
                biNormal = UnpackNormal(normal_albedo);
                biNormal.xy *= _BumpScale;
                biNormal.z = sqrt(1.0 - saturate(dot(biNormal.xy,biNormal.xy)));

                biNormal = half3(dot(i.tTW0.xyz,biNormal),dot(i.tTW1.xyz,biNormal),dot(i.tTW2.xyz,biNormal));

                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Diffuse.rgb;

                //环境光
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                //渐变贴图
                //float lambert = saturate(dot(biNormal,worldLightDir));
                float lambert = dot(biNormal,worldLightDir)*0.5+0.5;
                //float3 diffuseColor = tex2D(_RanmpTex,fixed2(lambert,lambert)).rgb;

                 //渐变纹理漫反射
                //float3 diffuse = _LightColor0.rgb * albedo *saturate(dot(biNormal,worldLightDir));

                 //颜色离散化
                float3 diffuseColor  = smoothstep(0,1,lambert);
                float toon = floor(diffuseColor * _Steps ) / _Steps;
                diffuseColor = lerp(diffuseColor,toon,_ToonEffect);
                float3 diffuse = _LightColor0.rgb * albedo * diffuseColor;


                //高光反射
                float3 halfVe = normalize(worldViewDir + worldLightDir);
                //高光遮罩
                float mask = tex2D(_MaskTex,i.uv2.xy).r * _MaskScale;

                float3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(biNormal,halfVe)),_Gloss) * mask;

                //外发光 N *V
                float rim = 1 - saturate(dot(biNormal,worldViewDir));
                fixed3 rimColor = _RimColor.rgb * pow(rim,_RimPower);


               return float4(ambient + diffuse + specular + rimColor,1);
            }
            ENDCG
        }
    }

    FallBack "Legacy Shaders/Transparent/VertexLit"
}
