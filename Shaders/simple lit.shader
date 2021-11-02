// supports lightmap, directional light, light probes, fog, emission

Shader "z3y/other/simple lit"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Base Map", 2D) = "white" {}
        _MainTexArray ("Base Map Array", 2DArray) = "white" {}
        [Space(10)]
        [Toggle(EMISSION)] _EnableEmission ("Enable Emission", Int) = 0
        [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)
        _EmissionMap ("Emission Map", 2D) = "white" {}

        [Toggle(TEXTUREARRAY)] _EnableTextureArray ("Texture Array", Float) = 0
        [Toggle(TEXTUREARRAYINSTANCED)] _EnableTextureArrayInstancing ("Instanced Array Index", Float) = 0
        _TextureIndex ("Instance Index", Int) = 0

        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" "RenderType"="Opaque" }
        Cull [_Cull]

        Pass
        {
            CGPROGRAM
            #pragma target 3.5
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            // #pragma multi_compile DIRECTIONAL LIGHTMAP_ON
            #pragma multi_compile_fwdbase
            #pragma skip_variants SHADOWS_SHADOWMASK SHADOWS_SCREEN SHADOWS_CUBE
            // #pragma skip_variants DIRLIGHTMAP_COMBINED DYNAMICLIGHTMAP_ON SHADOWS_SCREEN SHADOWS_SHADOWMASK LIGHTMAP_SHADOW_MIXING VERTEXLIGHT_ON
            #pragma fragmentoption ARB_precision_hint_fastest

            #pragma shader_feature_local EMISSION
            #pragma shader_feature_local TEXTUREARRAY
            #pragma shader_feature_local TEXTUREARRAYINSTANCED

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
                #if defined(TEXTUREARRAY)
                float3 uv0 : TEXCOORD0;
                #else
                float2 uv0 : TEXCOORD0;
                #endif
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
                #if defined(TEXTUREARRAY)
                float arrayIndex : TEXCOORD4;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
	            UNITY_VERTEX_OUTPUT_STEREO
            };

            static SamplerState defaultSampler;
            Texture2D _MainTex;
            SamplerState sampler_MainTex;
            half4 _MainTex_ST;
            half4 _Color;

            #if defined(TEXTUREARRAY)
            UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
            static float textureIndex;
            #endif

            #ifdef EMISSION
            Texture2D _EmissionMap;
            half3 _EmissionColor;
            #endif

            #ifdef INSTANCING_ON
            UNITY_INSTANCING_BUFFER_START(Props)
                #if defined (TEXTUREARRAYINSTANCED)
                    UNITY_DEFINE_INSTANCED_PROP(float, _TextureIndex)
                #endif
            UNITY_INSTANCING_BUFFER_END(Props)
            #endif

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.coord0.xy = TRANSFORM_TEX(v.uv0.xy, _MainTex);
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

                #if defined(TEXTUREARRAY)
                o.arrayIndex = v.uv0.z;
                #endif
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                #ifdef TEXTUREARRAYINSTANCED
                    UNITY_SETUP_INSTANCE_ID(i)
                #endif

                #ifndef TEXTUREARRAY
                    defaultSampler = sampler_MainTex;
                    half4 mainTexture = _MainTex.Sample(defaultSampler, i.coord0.xy);
                #else
                    defaultSampler = sampler_MainTexArray;
                    #ifdef TEXTUREARRAYINSTANCED
                        textureIndex = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureIndex);
                    #else
                        textureIndex = i.arrayIndex;
                    #endif
                    half4 mainTexture = UNITY_SAMPLE_TEX2DARRAY(_MainTexArray, float3(i.coord0.xy, textureIndex));
                #endif

                mainTexture *= _Color;

                half3 indirectDiffuse = 1;
                half3 light = 0;
                half3 emission = 0;


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
                emission = _EmissionMap.Sample(defaultSampler, i.coord0.xy) * _EmissionColor;
                #endif

                half4 finalColor = half4(mainTexture.rgb * (indirectDiffuse + light) + emission, 1);

                #ifdef USING_FOG
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                #endif
                return finalColor;
            }
            ENDCG
        }

        
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
        
    }
    CustomEditor "z3y.LitUIQuest"
    FallBack "VRChat/Mobile/Lightmapped"
}
