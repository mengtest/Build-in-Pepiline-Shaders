Shader "Unlit/Self-Illumination"
{
     Properties {
        _MainTex ("Base (RGB) Self-Illumination (A)", 2D) = "white" {}
    }
    SubShader {
        Pass {
            // Set up basic white vertex lighting
            //设置白色顶点光照
            Material {
                Diffuse (1,1,1,1)//漫反射颜色设置
                Ambient (1,1,1,1)//环境光反射颜色设置
            }
            Lighting On

            // Use texture alpha to blend up to white (= full illumination)
            // 使用纹理Alpha来混合白色（完全发光）
            SetTexture [_MainTex] {
                constantColor (1,1,1,1)    //自定义颜色
                combine constant lerp(texture) previous
            }
            // Multiply in texture
            // 和纹理相乘
            SetTexture [_MainTex] {
                combine previous * texture
            }
        }
    }
}
