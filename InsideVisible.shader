Shader "Unlit/InsideVisible" 
{
	Properties
    {
        [NoScaleOffset] 
		_MainTex("Base (RGB)", 2D) = "white" {}

        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull("Cull",float) = 1
	}

	SubShader
    {
		Tags { "RenderType" = "Opaque" }
		Cull [_Cull]

		Pass 
        {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;

			v2f vert(appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
		    ENDCG
        }
	}
}