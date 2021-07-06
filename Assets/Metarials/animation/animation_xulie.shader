Shader "Unlit/animation_xulie"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _HorizontalCount("horizontalCount",float) = 4
        _VerticalCount("verticalCount",float) = 4
        _Speed("Speed",float) = 1
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
  
        Pass
        {
            //Tags { "LightMode"="ForwardBase" }
            ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

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
            float _HorizontalCount;
            float _VerticalCount;
            float _Speed;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = floor(_Time.y * _Speed);
                float row = floor(time/_HorizontalCount);
                float column = time - row * _HorizontalCount;

                half2 uv = i.uv + half2(column,-row);
                uv.x /= _HorizontalCount;
                uv.y /= _VerticalCount;

                fixed4 col = tex2D(_MainTex, uv);
                return col;
            }
            ENDCG
        }
    }
}
