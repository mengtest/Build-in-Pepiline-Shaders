Shader "Custom/water"
{
    Properties
    {
        _ShallowWaterColor("ShallowWaterColor",Color)=(1,1,1,1)
        _DepthWaterColor("DepthWaterColor",Color)=(1,1,1,1)
        _TranAmount("TranAmount",Range(0,1)) = 0.5
        _DepthRange("DepathRange",Range(0,1.5)) = 1
        _WaterSpeed("WaterSpeed",Range(0,5)) = 1
        _NormalTex("NormalTex",2D)="bump"{}
        _Refract("Refract",Range(0,1)) = 0.5

        _SpecularColor("SpecularColor",Color)=(1,1,1,1)
        _Specular("Specular",Range(0,5))=1
        _Gloss("Gloss",Range(0,3)) = 1

        _WaveTex("WaveTex",2D)="white"{}
        _NoiseTex("NoiseTex",2D)="white"{}
        _WaveSpeed("WaveSpeed",Range(0,10))=1
        _WaveRange("WaveRange",Range(0,2))=0.5
        _WaveRangB("WaveRangB",Range(0,2))=1
        _WaveDelta("WaveDelta",Range(0,10))=0.5
        _Distortion("Distortion",Range(0,2)) = 1

        _CubeMap("CubMap",Cube)="_Skybox"{}
        _FresnelVal("FresnelVal",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        GrabPass{"_GrabPassTex"}
        ZWrite Off
        //Blend OneMinusDstColor One

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf WaterLight fullforwardshadows vertex:vert alpha

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D_float _CameraDepthTexture;//摄像机深度图 固定名字
        sampler2D _NormalTex;
        sampler2D _WaveTex;
        sampler2D _NoiseTex;
        sampler2D _GrabPassTex;//屏幕抓取
        samplerCUBE _CubeMap;

        struct Input
        {
            float2 uv_NormalTex;
            float2 uv_NoiseTex;
            float4 proj;
            float3 viewDir;
            float3 worldRefl;
            float3 worldNormal;
            INTERNAL_DATA
        };

        float4 _GrabPassTex_TexelSize;
        float _Distortion;
        float _WaveSpeed;
        float _WaveRange;
        float _WaveRangB;
        float _WaveDelta;
        fixed4 _ShallowWaterColor;
        fixed4 _DepthWaterColor;

        float _TranAmount;
        half _DepthRange;
        fixed _WaterSpeed;
        float _Refract;

        fixed4 _SpecularColor;
        fixed _Specular;
        fixed _Gloss;
        float _FresnelVal;
        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        //光照
        fixed4 LightingWaterLight(SurfaceOutput s,fixed3 lightDir,half3 viewDir,fixed atten)
        {
            float diffuseFactor = saturate(dot(normalize(lightDir),s.Normal));
            float3 halfDir = saturate(normalize(lightDir + viewDir));
            float spec = pow(saturate(dot(halfDir,s.Normal)),s.Specular * 128) * s.Gloss;
            fixed4 c;
            c.rgb = (s.Albedo * _LightColor0.rgb * diffuseFactor + _SpecularColor.rgb * spec * _LightColor0.rgb) * atten;
            c.a = s.Alpha + spec * _SpecularColor.a;

            return c;
        }

        void vert(inout appdata_full v, out Input i)
        {
            UNITY_INITIALIZE_OUTPUT(Input,i);
            //屏幕坐标
            i.proj = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
            //计算顶点摄像机空间的深度：距离裁剪平面的距离，线性变化；
            COMPUTE_EYEDEPTH(i.proj.z);
        }

        void surf (Input IN, inout SurfaceOutput o)
        {
            //深度图采样 SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(IN.proj))
            //tex2Dproj(_CameraDepthTexture,IN.proj) 等于 tex2D 采用后除以 w
            //Linear01Depth// 转换成[0,1]内的线性变换深度值
            //LinearEyeDepth 变换成视角空间的 线性值

            //计算当前像素深度
            half depth = LinearEyeDepth(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(IN.proj)).r);
            //深度 - 像素的深度 得到一个差值，可以表示水域的深浅
            half deltaDepth = depth - IN.proj.z;//水深
            fixed4 c = lerp(_ShallowWaterColor,_DepthWaterColor,min(deltaDepth,_DepthRange)/_DepthRange);

            //法线不断变换 变换的地方光照也会变换 产生一个水流动的效果
            //采样的时候 偏移uv坐标
            float4 bumpOffset1 = tex2D(_NormalTex,IN.uv_NormalTex + float2(_WaterSpeed * _Time.x,0));
            float4 bumpOffset2 = tex2D(_NormalTex,float2(1 - IN.uv_NormalTex.y,IN.uv_NormalTex.x) + float2(_WaterSpeed * _Time.x,0));

            float4 offsetColor = (bumpOffset1 + bumpOffset2)/2;
            float2 offset = UnpackNormal(offsetColor).xy * _Refract;
            float4 bumpColor1 = tex2D(_NormalTex,IN.uv_NormalTex + offset+ float2(_WaterSpeed * _Time.x,0));
            float4 bumpColor2 = tex2D(_NormalTex,float2(1 - IN.uv_NormalTex.y,IN.uv_NormalTex.x) + offset+ float2(_WaterSpeed * _Time.x,0));
            float3 bumpVal = UnpackNormal((bumpColor1 + bumpColor2)/2).xyz;
            o.Normal = bumpVal;

            //波浪
            half waveB = 1 - min(_WaveRangB,deltaDepth)/_WaveRangB;
            fixed4 noiserColor = tex2D(_NoiseTex,IN.uv_NoiseTex);
            fixed4 waveColor1 = tex2D(_WaveTex,float2(waveB + _WaveRange * sin(_Time.y * _WaveSpeed + noiserColor.r),1) + offset);
            waveColor1.rgb *= (1- (sin(_Time.x * _WaveSpeed + noiserColor.r)+1)/2)*noiserColor.r;
            fixed4 waveColor2 = tex2D(_WaveTex,float2(waveB + _WaveRange * sin(_Time.y * _WaveSpeed + _WaveDelta + noiserColor.r),1) + offset);
            waveColor2.rgb *= (1- (sin(_Time.x * _WaveSpeed + _WaveDelta + noiserColor.r)+1)/2)*noiserColor.r;

            //抓屏，根据法线扰动
            offset = bumpVal.xy * _Distortion * _GrabPassTex_TexelSize.xy;
            float2 uv1 = (offset * IN.proj.z + IN.proj.xy)/IN.proj.w;
            fixed3 refrCol = tex2D(_GrabPassTex,uv1).rgb; //反射
            float3 worldRefl = WorldReflectionVector(IN,o.Normal);
            fixed3 refraction = texCUBE(_CubeMap,worldRefl).rgb; //折射
            fixed fresnel = _FresnelVal + (1 - _FresnelVal) * pow((1 - dot(IN.viewDir,WorldNormalVector(IN,o.Normal))),5);//菲尼尔系数
            fixed3 refAndRelf = lerp(refraction,refrCol,saturate(fresnel));//菲尼尔反射

            o.Albedo = c  + refAndRelf + (waveColor1.rgb + waveColor2.rgb) * waveB;

            o.Alpha = min(_TranAmount,deltaDepth)/_TranAmount;
            o.Specular = _Specular;
            o.Gloss = _Gloss;
        }
        ENDCG
    }

    //FallBack "Diffuse"
}
