Shader "ASGame/BRDF_NPC_1"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _RanmpTex("渐变纹理", 2D) = "white" {}
        _Color_Dif("Color InIt",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 8
        _Color_Specu("Color Specular",Color) = (1,1,1,1)

        _OutLineColor("描边颜色",Color)=(0,0,0,0)
        _OutLine("描边粗细",Range(0,0.1)) = 0.01

         _RimColor("_RimColor",Color)=(1,1,1,1)
        _RimPower("_RimPower",Range(0.0001,1)) = 0.01
    }

    SubShader
    {
       
        Pass
        {
            Tags {"LightMode"="ForwardBase" }
            
            Cull Front 
            //ZWrite Off
            //Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _OutLineColor;
            float _OutLine;
            struct v2f
            {
                 float4 vertex : SV_POSITION;
            };
     
            v2f vert (appdata_base v)
            {
                //物体空间(Object)法线外扩
                //v.vertex.xyz += v.normal * _OutLine;
                //v2f o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                //return o;

                //视角空间(View)法线外扩
                //float4 vpos = float4(UnityObjectToViewPos(v.vertex),1.0);
                //float3 vnormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                //vpos += float4(vnormal,0) * _OutLine;
                //v2f o;
                //o.vertex = mul(UNITY_MATRIX_P,vpos);
                //return o;

                //裁剪空间法线外扩
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 vnormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                float2 clipNormal = TransformViewToProjection(vnormal).xy;
                 o.vertex.xy += clipNormal * _OutLine;

                return o;
            }

             fixed4 frag (v2f i) : SV_Target
            {
                return _OutLineColor;
            }
            ENDCG
        }


        Pass
        {
            
            Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
            Cull Back  
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
            sampler2D _RanmpTex;
            float4 _RanmpTex_ST;

            
            fixed4 _RimColor;
            float _RimPower;

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

                fixed halfLBT = dot(N,I) * 0.5 + 0.5;


                float diffuseColor = tex2D(_RanmpTex,fixed2(halfLBT,halfLBT)*_RanmpTex_ST.xy + _RanmpTex_ST.zw).rgb * albedo;
                //漫反射
                float3 diffuse = _LightColor0.rgb * diffuseColor;

                //高光反射
                float3 H = normalize(V + I);

                float3 specular = _LightColor0.rgb * _Color_Specu * pow(max(0,dot(H,N)),_Gloss);


                 //外发光 N *V
                float rim = 1 - max(0,dot(N,V));
                fixed4 rimColor = _RimColor * pow(rim,1/_RimPower);

                float3 col = ambient + diffuse + rimColor + specular;
 
                return float4(col,1.0);
            }
            ENDCG
        }
    }
}
