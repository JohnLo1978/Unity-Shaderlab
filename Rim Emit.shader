Shader "Unlit/Rim" 
{
	Properties 
	{
		[HDR]
		_EmitCol("Emit Color",Color) = (1,1,1,1)
		[HDR]
		_OutlineColor ("Outline Color", Color) = (1,1,1,1)
		_OutlineWidth ("Outline Width", Range(0, 0.01)) = 0.001
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" }

		// 深度
		Pass {
			Cull Off	// 双面渲染
			ZWrite On	// 允许像素深度值写入深度缓冲区
			ColorMask 0	// 禁止像素颜色值写入颜色缓冲区
			CGPROGRAM
			float4 _Color;
			#pragma vertex vert 
			#pragma fragment frag

			float4 vert(float4 vertexPos : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertexPos);
			}

			float4 frag(void) : COLOR
			{
				return _Color;
			}
			ENDCG
		}

		// 菲涅尔半透明
		Pass 
		{
			ZWrite Off
			Blend SrcAlpha One

			CGPROGRAM  
			#pragma vertex vert 
			#pragma fragment frag 

			#include "UnityCG.cginc"  

			struct appdata  
			{
				float4 vertex : POSITION; 
				half2 uv0 : TEXCOORD0; 
				half3 normal : NORMAL; 
			};

			struct v2f
			{
				float4 pos : SV_POSITION; 
				float2 uv0 : TEXCOORD0;
				float3 posWS : TEXCOORD1;
				float3 nDirWS : TEXCOORD2;
			};


			float4 _EmitCol;
			

			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv0 = v.uv0;
				o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.nDirWS = normalize(mul(float4(v.normal,0.0), unity_WorldToObject).xyz);
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				float3 nDirWS = normalize(i.nDirWS);
				float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
				float ndotv = saturate(dot(nDirWS, vDirWS));
				float alpha = saturate(_EmitCol.a / ndotv);
				return float4(_EmitCol.xyz, alpha);
			}
			ENDCG
		}

		// 描边
		Pass
        {
			Cull Front
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

			half4 _OutlineColor;
			float _OutlineWidth;

            v2f vert (appdata v)
            {
                v2f o;
				float4 viewPos = float4(UnityObjectToViewPos(v.vertex), 1.0);
				float3 viewNormal = mul(UNITY_MATRIX_IT_MV, v.normal);

				viewNormal.z = -0.5;
				float3 normal = normalize(viewNormal);
				viewPos += float4(normal, 1.0) * _OutlineWidth;

				o.pos = mul(UNITY_MATRIX_P, viewPos);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
		}
	}
}
