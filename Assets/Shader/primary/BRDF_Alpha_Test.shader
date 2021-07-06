Shader "ASGame/BRDF_Alpha_Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color_Dif("Color InIt",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,20)) = 8
        _Color_Specu("Color Specular",Color) = (1,1,1,1)

        _Cutoff("透明度",Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags { "Queue" = "AlphaTest" "IgnoreProjector"="True"}
        LOD 100
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
            float _Cutoff;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
     
                //纹理采样
                fixed4 texColor = tex2D(_MainTex, i.uv);

                if( (texColor.a - _Cutoff) < 0.0) discard; 

                fixed3 albedo = texColor.rgb * _Color_Dif.rgb;

                //需要 V I H N
                float3 V = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 N = normalize(i.worldNormal);  
                float3 I = normalize(UnityWorldSpaceLightDir(i.worldPos));


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

    FallBack "Transparent/Cutout/VertexLit"
}
