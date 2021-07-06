Shader "ASGame/BRDF_Texture_Single"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color_Dif("Color InIt",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,20)) = 8
        _Color_Specu("Color Specular",Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {        
                float4 vertex : SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            fixed4 _Color_Dif;
            fixed4 _Color_Specu;
            float _Gloss;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                //o.uv = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //需要 V I H N
                float3 V = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 N = normalize(i.worldNormal);  
                float3 I = normalize(UnityWorldSpaceLightDir(i.worldPos));

                //纹理采样
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color_Dif.rgb;

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //漫反射
                float3 diffuse = _LightColor0.rgb * albedo * max(0,dot(N,I));

                //高光反射
                float3 H = normalize(V + I);

                float3 specular = _LightColor0.rgb * _Color_Specu * pow(max(0,dot(H,N)),_Gloss);

                float3 col = ambient + diffuse + specular;
 
                return float4(col,1.0);
            }
            ENDCG
        }
    }
}
