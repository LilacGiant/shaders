// supports lightmap, directional light, light probes, fog, emission

Shader "Mobile/Lit Quest"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Base Map", 2D) = "white" {}
        [Space(10)]
        [Toggle(EMISSION)] _EnableEmission ("Enable Emission", Int) = 0
        [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)
        _EmissionMap ("Emission Map", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma target 2.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            // #pragma multi_compile DIRECTIONAL LIGHTMAP_ON
            #pragma multi_compile_fwdbase
            #pragma skip_variants SHADOWS_SHADOWMASK SHADOWS_SCREEN SHADOWS_DEPTH SHADOWS_CUBE
            // #pragma skip_variants DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON SHADOWS_SCREEN SHADOWS_SHADOWMASK LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON
            #pragma fragmentoption ARB_precision_hint_fastest

            #pragma shader_feature_local EMISSION

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            // #include "AutoLight.cginc"

            

            #define USING_FOG (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))

            struct appdata
            {
                float4 vertex : POSITION;
                #if !defined(LIGHTMAP_ON) || defined(DIRECTIONAL)
                float3 normal : NORMAL;
                #endif
                float2 uv0 : TEXCOORD0;
                #ifdef LIGHTMAP_ON
                float2 uv1 : TEXCOORD1;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                #ifdef LIGHTMAP_ON
                float4 coord0 : TEXCOORD0;
                #else
                float2 coord0 : TEXCOORD0;
                #endif
                #if !defined(LIGHTMAP_ON) || defined(DIRECTIONAL)
                float3 worldNormal : TEXCOORD1;
                #endif
                #ifdef DIRECTIONAL
                float4 worldPos : TEXCOORD2;
                #endif
                #ifdef USING_FOG
                UNITY_FOG_COORDS(3)
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
	            UNITY_VERTEX_OUTPUT_STEREO
            };

            Texture2D _MainTex;
            SamplerState sampler_MainTex;
            half4 _MainTex_ST;
            half4 _Color;

            #ifdef EMISSION
            Texture2D _EmissionMap;
            half3 _EmissionColor;
            #endif

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.coord0.xy = TRANSFORM_TEX(v.uv0, _MainTex);
                #ifdef LIGHTMAP_ON
                o.coord0.zw = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                #if !defined(LIGHTMAP_ON) || defined(DIRECTIONAL)
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                #endif
                #ifdef DIRECTIONAL
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                #endif
                #ifdef USING_FOG
                UNITY_TRANSFER_FOG(o,o.pos);
                #endif
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 indirectDiffuse = 1;
                half3 light = 0;
                half3 emission = 0;

                half4 mainTexture = _MainTex.Sample(sampler_MainTex, i.coord0.xy) * _Color;

                #ifdef LIGHTMAP_ON
                indirectDiffuse = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.coord0.zw));
                #else
                indirectDiffuse = max(0, ShadeSH9(float4(i.worldNormal, 1)));
                #endif

                #ifdef DIRECTIONAL
                    float3 lightDirection = UnityWorldSpaceLightDir(i.worldPos);
                    half NoL = saturate(dot(i.worldNormal, lightDirection));
                    light = NoL * _LightColor0.rgb;
                #endif

                #ifdef EMISSION
                emission = _EmissionMap.Sample(sampler_MainTex, i.coord0.xy) * _EmissionColor;
                #endif

                half4 finalColor = half4(mainTexture.rgb * (indirectDiffuse + light) + emission, 1);

                #ifdef USING_FOG
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                #endif
                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "VRChat/Mobile/Lightmapped"
}
