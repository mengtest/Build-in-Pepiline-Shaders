Shader "ASGame/BRDF_NPC_2"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Diffuse("Color InIt",Color) = (1,1,1,1)
        _OutLineColor("描边颜色",Color)=(0,0,0,0)
        _OutLine("描边粗细",Range(0,0.1)) = 0.01
        _Steps("_Steps",Range(1,30)) = 1
        _ToonEffect("_ToonEffect",Range(0,1)) = 0.5

        _RimColor("_RimColor",Color)=(1,1,1,1)
        _RimPower("_RimPower",Range(0.0001,1)) = 0.01
    }

    SubShader
    {
       
        Pass
        {
            Tags {"LightMode"="ForwardBase" }
            
            Cull Front 
       
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

            fixed4 _Diffuse;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Steps;
            float _ToonEffect;

            fixed4 _RimColor;
            float _RimPower;
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
                //需要 I  N
                float3 N = normalize(i.worldNormal);  
                float3 I = normalize(UnityWorldSpaceLightDir(i.worldPos));

                //纹理采样
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                float difLight = dot(N,I) * 0.5 + 0.5;

                //颜色平滑在【0 1】之间
                difLight = smoothstep(0,1,difLight);
                //颜色离散化
                float toon = floor(difLight * _Steps ) / _Steps;
                difLight = lerp(difLight,toon,_ToonEffect);

                //漫反射
                float3 diffuse = _LightColor0.rgb  * albedo *  _Diffuse.rgb * difLight;

                //外发光 N *V
                float V = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float rim = 1 - max(0,dot(N,V));
                fixed3 rimColor = _RimColor.rgb * pow(rim,1/_RimPower);


                return float4(ambient + diffuse + rimColor,1.0);
            }
            ENDCG
        }
    }

     FallBack "Transparent/Cutout/VertexLit"
}
