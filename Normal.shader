Shader "Unlit/Normal"
{
    Properties
    {
        [Normal]
        _Normalmap ("Normalmap",2D) = "bump" {}
        _NormalFactor("Normal Factor",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase_fullshadows

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 tDirWS : TEXCOORD1;
                float3 bDirWS : TEXCOORD2;
                float3 nDirWS : TEXCOORD3;
            };


            sampler2D _Normalmap;
            float _NormalFactor;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.tDirWS = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0)).xyz); // 0 表示方向向量
                o.bDirWS = normalize(cross(o.nDirWS,o.tDirWS) * v.tangent.w);         
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDirTS = UnpackNormal(tex2D(_Normalmap,i.uv));
                float3x3 TBN = float3x3(i.tDirWS,i.bDirWS,i.nDirWS);
                float3 nDir = normalize(mul(nDirTS,TBN));
                float3 final = lerp(i.nDirWS,nDir,_NormalFactor);

                return float4(final,1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
