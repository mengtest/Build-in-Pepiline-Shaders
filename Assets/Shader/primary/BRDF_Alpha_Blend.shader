Shader "ASGame/BRDF_Alpha_Blend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color_Dif("Color InIt",Color) = (1,1,1,1)
         _NormalTex ("法线贴图", 2D) = "white" {}

        _Gloss("Gloss",Range(8.0,20)) = 8
        _Color_Specular("高光颜色",Color) = (1,1,1,1)

        _MaskTex ("高光遮罩贴图", 2D) = "white" {}
        _MaskScale("遮罩比列",Range(0,50.0)) = 1

         _AlphaTex ("透明贴图", 2D) = "white" {}
        _AlphaScale("透明度",Range(0,1)) = 0.5

        
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Transparent" "IgnoreProjector"="True"}
        LOD 100

        Pass
        {
             ZWrite On
             ColorMask 0
        }
        
        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front
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
                float4 tangent:TANGENT;//切线
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {        
                float4 vertex : SV_POSITION;
               // float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float4 uv : TEXCOORD2;
                float2 maskuv : TEXCOORD3;

                float3 tTW1:TEXCOORD4;
                float3 tTW2:TEXCOORD5;
                float3 tTW3:TEXCOORD6;
            };

            fixed4 _Color_Dif;
            fixed4 _Color_Specular;
            float _Gloss;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;

            sampler2D _AlphaTex;
            float _AlphaScale;

            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            float4 _MaskScale;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
              
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_NormalTex);
                o.maskuv = TRANSFORM_TEX(v.texcoord,_MaskTex);
                
                //计算矩阵 t b n
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent));
                float3 binormal = cross(normalize( worldNormal),normalize(worldTangent));

                o.tTW1 = float3(worldTangent.x,binormal.x,worldNormal.x);
                o.tTW2 = float3(worldTangent.y,binormal.y,worldNormal.y);
                o.tTW3 = float3(worldTangent.z,binormal.z,worldNormal.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
     
               fixed4 texAlphaColor = tex2D(_AlphaTex, i.uv);
                
                //纹理采样
               fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color_Dif.rgb;

                //需要 V I H N
               float3 V = normalize(UnityWorldSpaceViewDir(i.worldPos));
               // float3 N = normalize(i.worldNormal);  
               float3 I = normalize(UnityWorldSpaceLightDir(i.worldPos));

               fixed4 normalColor = tex2D(_NormalTex, i.uv.zw);
               
               fixed3 tangentNormal = UnpackNormal(normalColor);
               tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));

              tangentNormal = normalize(half3(dot(i.tTW1,tangentNormal),dot(i.tTW2,tangentNormal),dot(i.tTW3,tangentNormal)));

               float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //漫反射
                float3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,I));


                fixed4 maskColor =  tex2D(_MainTex, i.maskuv) ;
                //高光反射
                float3 H = normalize(V + I);

                float3 specular = _LightColor0.rgb * _Color_Specular * pow(max(0,dot(H,tangentNormal)),_Gloss) * (maskColor.r * 1);

                float3 col = ambient + diffuse + specular;
 
                return float4(col,texAlphaColor.a * _AlphaScale);
            }
            ENDCG
        }

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back
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
                float4 tangent:TANGENT;//切线
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {        
                float4 vertex : SV_POSITION;
               // float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float4 uv : TEXCOORD2;
                float2 maskuv : TEXCOORD3;

                float3 tTW1:TEXCOORD4;
                float3 tTW2:TEXCOORD5;
                float3 tTW3:TEXCOORD6;
            };

            fixed4 _Color_Dif;
            fixed4 _Color_Specular;
            float _Gloss;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;

            sampler2D _AlphaTex;
            float _AlphaScale;

            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            float4 _MaskScale;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
              
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_NormalTex);
                o.maskuv = TRANSFORM_TEX(v.texcoord,_MaskTex);
                
                //计算矩阵 t b n
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent));
                float3 binormal = cross(normalize( worldNormal),normalize(worldTangent));

                o.tTW1 = float3(worldTangent.x,binormal.x,worldNormal.x);
                o.tTW2 = float3(worldTangent.y,binormal.y,worldNormal.y);
                o.tTW3 = float3(worldTangent.z,binormal.z,worldNormal.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
     
               fixed4 texAlphaColor = tex2D(_AlphaTex, i.uv);
                
                //纹理采样
               fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color_Dif.rgb;

                //需要 V I H N
               float3 V = normalize(UnityWorldSpaceViewDir(i.worldPos));
               // float3 N = normalize(i.worldNormal);  
               float3 I = normalize(UnityWorldSpaceLightDir(i.worldPos));

               fixed4 normalColor = tex2D(_NormalTex, i.uv.zw);
               
               fixed3 tangentNormal = UnpackNormal(normalColor);
               tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));

              tangentNormal = normalize(half3(dot(i.tTW1,tangentNormal),dot(i.tTW2,tangentNormal),dot(i.tTW3,tangentNormal)));

               float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //漫反射
                float3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,I));


                fixed4 maskColor =  tex2D(_MainTex, i.maskuv) ;
                //高光反射
                float3 H = normalize(V + I);

                float3 specular = _LightColor0.rgb * _Color_Specular * pow(max(0,dot(H,tangentNormal)),_Gloss) * (maskColor.r * 1);

                float3 col = ambient + diffuse + specular;
 
                return float4(col,texAlphaColor.a * _AlphaScale);
            }
            ENDCG
        }
    }

    FallBack "Transparent/Cutout/VertexLit"
}
