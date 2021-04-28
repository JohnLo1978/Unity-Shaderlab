Shader "Unlit/Cubemap_Reflection"
{
    Properties
    {
        [NoScaleOffset] 
        _Cubemap("Cubemap",Cube) = "" {}

        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull("Cull",float) = 1

        _Mip("Mip",Range(0,8)) = 0
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
            float _Mip;

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
                float3 vDirWS = _WorldSpaceCameraPos.xyz - i.posWS;
                float3 vrDirWS = reflection(-vDirWS,i.nDirWS);
                float4 cubemap = texCUBElod(_Cubemap,float4(vrDirWS,_Mip)); 
                return cubemap;
            }
            ENDCG
        }
    }
}