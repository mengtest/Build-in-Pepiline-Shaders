Shader "Unlit/Stencil_Test_ball"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
     }
    SubShader
    {
        Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }

        Stencil
        {
            Ref 1
            Comp Always
            Pass Replace
        }

         Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            sampler2D _MainTex;
            float4 _MainTex_ST;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb;
                return fixed4(albedo,1);
            }
            ENDCG
        }
    }
}