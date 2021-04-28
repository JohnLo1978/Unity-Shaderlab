Shader "Unlit/Gray"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Origin("Origin",Vector) = (0,0,0,1)
        _Radius("Radius",Range(0,100)) = 20
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 posWS : TEXCOORD1;
            };
            
            float4 _Origin;
            float _Radius;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                // 加权平均 人眼对绿色敏感
                float val = 0.299 * col.r + 0.578 * col.g + 0.114 * col.b;
                float3 gray = val.xxx;
                float factor = saturate(_Radius - distance(_Origin.xyz,i.posWS.xyz));
                col = lerp(col,float4(gray,1),factor);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
