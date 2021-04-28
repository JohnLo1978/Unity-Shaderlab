Shader "Unlit/Cubemap_Refraction"
{
    Properties
    {
        [NoScaleOffset] 
        _Cubemap("Cubemap",Cube) = "" {}

        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull("Cull",float) = 1

        _RatioSrc("Ratio Src",float) = 1
        _RatioDst("Ratio Dst",float) = 1.33
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull [_Cull]

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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
            };

            samplerCUBE _Cubemap;
            float _RatioSrc;
            float _RatioDst;

            // 参考 《入门精要》 P132
            float3 reflection(float3 l,float3 n)
            {
                return l - 2 * dot(l,n) * n;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // 空气 -> 玻璃
                float ratio = _RatioSrc / _RatioDst;
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
                float3 r = refract(-vDirWS,i.nDirWS,ratio);
                //float4 cubemap = texCUBElod(_Cubemap,float4(r,_Mip));
                float4 cubemap = float4(texCUBE(_Cubemap, r).rgb,1);

                /*
                float ratio = 1.00 / 1.52;
                ec3 I = normalize(Position - cameraPos);
                vec3 R = refract(I, normalize(Normal), ratio);
                FragColor = vec4(texture(skybox, R).rgb, 1.0);
                */
                return cubemap;
            }
            ENDCG
        }
    }
}