Shader "Unlit/BRDF_Outline"
{
    Properties
    {
        _OutLine("OutLine",Color)=(1,1,1,1)
        _line("line",Range(0.0001,1)) = 0.01
    }
    SubShader
    {
     
        LOD 100

        Pass
        {
           Tags { "RenderType"="Opaque"}

            Name "Outline"
            Cull Front 
            //ZWrite Off
            //Blend One  One

            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _OutLine;
            float _line;
            struct v2f
            {
                 float4 vertex : SV_POSITION;
            };
     
            v2f vert (appdata_base v)
            {
                //物体空间(Object)法线外扩
                //v.vertex.xyz += v.normal * _line;
                //v2f o;
                //o.vertex = UnityObjectToClipPos(v.vertex);
                //return o;

                //视角空间(View)法线外扩
                //float4 vpos = float4(UnityObjectToViewPos(v.vertex),1.0);
                //float3 vnormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                //vpos += float4(vnormal,0) * _line;
                //v2f o;
                //o.vertex = mul(UNITY_MATRIX_P,vpos);
                //return o;

                //裁剪空间法线外扩
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 vnormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                float2 clipNormal = TransformViewToProjection(vnormal).xy;
                 o.vertex.xy += clipNormal * _line;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutLine;
            }

            ENDCG
        }
    }
}
