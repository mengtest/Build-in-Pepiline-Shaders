Shader "Unlit/BRDF_ShadowTest"
{
    Properties
    {
        _MainTex("MainTex",2D)="white"{}
        _Color("_Color",Color)=(1,1,1,1)
        _Specular("_Specular",Color)=(1,1,1,1)
        _Gloss("_Gloss",Range(1,100)) = 30
        _AlphaScale("_AlphaScale",Range(0,1)) =0.2
    }
    SubShader
    {
        
        LOD 100

        Pass
        {
            Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True"}

            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal :NORMAL;
                float2 uv :TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float3 vertexLight:TEXCOORD2; 
                LIGHTING_COORDS(3,4)//
                float2 uv:TEXCOORD5;

            };

            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;

            sampler2D _MainTex;
            fixed4 _MainTex_ST;
            fixed _AlphaScale;
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
                
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normalDir = normalize(i.worldNormal);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float3 viewDir =  normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

               float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

               fixed4 albedo = tex2D(_MainTex, i.uv);
               float3 diffuse = albedo.rgb * _LightColor0.rgb * _Color.rgb * saturate(dot(normalDir,lightDir));

               float3 halfDir = normalize(lightDir+viewDir);

               float3 specualr = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(normalDir,halfDir)),_Gloss);

               //fixed shadow = SHADOW_ATTENUATION(i);
               //这个函数包含了光照衰减和阴影
               //因为ForwardBase逐像素光影一般是方向光，衰减为1，atten在这里实际是阴影值
               UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
               return fixed4(ambient + (diffuse + specualr)*atten + i.vertexLight ,albedo.a * _AlphaScale);
            }
            ENDCG
        }
    }
      Fallback "Diffuse"  
     //Fallback "Transparent/Cutout/VertexLit"
}
