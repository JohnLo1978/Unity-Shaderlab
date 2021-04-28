Shader "Unlit/Dota2"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("BaseCol", 2D) = "white" {}
        _NormTex ("NormTex",2D) = "bump" {}
        _Cubemap ("Cubemap",Cube) = "_Skybox" {}
        _DiffWarpTex("DiffWarpTex",2D) = "gray" {}
        _FresWarpTex("FresWarpTex  R:Col  G:Rim  B:Spec",2D) = "gray" {}
        _MetalMask("MetalMask",2D) = "black" {}
        _RimMask("RimMask",2D) = "black" {}
        _EmitMask("EmitMask",2D) = "black" {}
        _SpecExp("SpecExp",2D) = "gary"{}
        _SpecMask("SpecMask",2D) = "black" {}

        [Header(DirDiff)]
        _LightCol("LightCol",color) = (1,1,1,1)

        [Header(DirSpec)]
        _SpecPow("SpecPow",range(0,100)) = 5
        _SpecInt("SpecInt",range(0,10)) = 5

        [Header(EnvDiff)]
        _EnvCol("EnvCol",color) = (1,1,1,1)
        _EnvDiffInt("EnvDiffInt",Range(0,1)) = 0.5

        [Header(EnvSpec)]
        _EnvSpecInt("EnvSpecInt",range(0,60)) = 0.5

        [Header(RimLight)]
        [HDR]_RimCol("RimCol",color) = (1,1,1,1)

        [Header(Emission)]
        _EmitInt("EmitInt",range(0,10)) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Cull Off
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float4 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float3 tDirWS : TEXCOORD3;
                float3 bDirWS : TEXCOORD4;
                LIGHTING_COORDS(5,6)    // 投影相关
                
            };

            sampler2D _MainTex;
            sampler2D _NormTex;
            samplerCUBE _Cubemap;
            sampler2D _DiffWarpTex;
            sampler2D _FresWarpTex;
            sampler2D _MetalMask;
            sampler2D _RimMask;
            sampler2D _EmitMask;
            sampler2D _SpecExp;
            sampler2D _SpecMask;

            // DirDiff
            float3 _LightCol;
            // DirSpec
            float _SpecPow;
            float _SpecInt;
            // EnvDiff
            float3 _EnvCol;
            float _EnvDiffInt;
            // EnvSpec
            float _EnvSpecInt;
            // RimLight
            float3 _RimCol;
            // Emission
            float _EmitInt;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv0 = v.uv0;
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.tDirWS = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0)).xyz);
                o.bDirWS = normalize(cross(o.nDirWS,o.tDirWS) * v.tangent.w);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 nDirTS = UnpackNormal(tex2D(_NormTex,i.uv0));
                float3x3 TBN = float3x3(i.tDirWS,i.bDirWS,i.nDirWS);

                float3 nDirWS = normalize(mul(nDirTS,TBN));
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
                float3 vrDirWS = reflect(-vDirWS,nDirWS);
                float3 lDirWS = _WorldSpaceLightPos0.xyz;
                float3 lrDirWS = reflect(-lDirWS,nDirWS);
                float3 hDirWS = normalize(vDirWS+lDirWS);


                float ndotl = dot(nDirWS,lDirWS);
                float ndotv = dot(nDirWS,vDirWS);
                float vdotr = dot(vDirWS,lrDirWS);


                float4 var_MainTex = tex2D(_MainTex,i.uv0);
                float var_SpecExp = tex2D(_SpecExp,i.uv0);
                float3 var_Cubemap = texCUBElod(_Cubemap,float4(vrDirWS,lerp(8,0,var_SpecExp.r))).rgb;
                float var_MetalMask = tex2D(_MetalMask,i.uv0).r;
                float var_EmitMask = tex2D(_EmitMask,i.uv0).r;
                float3 var_FresWarpTex = tex2D(_FresWarpTex,ndotv); // ?
                float var_SpecMask = tex2D(_SpecMask,i.uv0).r;
                float var_RimMask = tex2D(_RimMask,i.uv0).r;

                float shadow = LIGHT_ATTENUATION(i);


                // diffCol <=> 漫反射纹理
                float3 diffCol = lerp(var_MainTex.rgb,float3(0,0,0),var_MetalMask);
                // specCol <=> 高光颜色纹理
                float3 specCol = lerp(var_MainTex.rgb,float3(0.3,0.3,0.3),1);       // 1 - var_SpecTint 采样后的高光染色纹理
                // 菲涅尔
                float3 fres = lerp(var_FresWarpTex,0,var_MetalMask);
                float fresCol = fres.r;
                float fresRim = fres.g;
                float fresSpec = fres.b;
                // 光源漫反射
                float halfLambert = ndotl * 0.5 + 0.5;
                float3 var_DiffWarpTex = tex2D(_DiffWarpTex,float2(halfLambert,0.2));
                float3 dirDiff = diffCol * var_DiffWarpTex * _LightCol;
                // 光源高光反射
                float blinnPhong = pow(dot(hDirWS,nDirWS),var_SpecExp * _SpecPow);
                float3 dirSpec = specCol * max(blinnPhong,fresSpec) *  _SpecInt * _LightCol;
                // 环境漫反射
                float3 envDiff = diffCol * _EnvCol * _EnvDiffInt;
                // 环境高光反射
                float reflectInt = max(fresSpec,var_MetalMask) * var_SpecMask;
                float3 envSpec = specCol * reflectInt * var_Cubemap * _EnvSpecInt;
                // 轮廓光
                float3 rimLight = _RimCol * fresRim * var_RimMask * max(0,nDirWS.g);
                // 自发光
                float3 emission = diffCol * var_EmitMask * _EmitInt;

                
                float3 finalRGB = (dirDiff+dirSpec) * shadow + envDiff + envSpec + max(rimLight,emission);
                
                return float4(finalRGB,1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
