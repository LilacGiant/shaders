#ifndef VRS_PASS
#define VRS_PASS

#pragma exclude_renderers gles

#ifdef UNITY_UI_CLIP_RECT
#define ENABLE_GSAA
#endif

#ifdef _DETAIL_MULX2
#define ENABLE_BICUBIC_LIGHTMAP
#endif






UNITY_DECLARE_TEX2D(_MainTex);
float4 _MainTex_ST;
float4 _Color;


#if (PROP_ENABLENORMALMAP==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_NORMALMAP
UNITY_DECLARE_TEX2D(_BumpMap);
float4 _BumpMap_ST;
float _BumpScale;
#endif

float _Metallic;
float _Roughness;

#ifdef UNITY_UI_ALPHACLIP
#define ENABLE_PACKED_MODE
Texture2D _PackedTexture;
float _OcclusionStrength;
#else

#if (PROP_ENABLEMETALLICMAP==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_METALLICMAP
Texture2D _MetallicMap;
#endif



#if (PROP_ENABLEROUGHNESSMAP==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_ROUGHNESSMAP
Texture2D _RoughnessMap;
#endif


#if (PROP_ENABLEOCCLUSION==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_OCCLUSIONMAP
Texture2D _OcclusionMap;
float _OcclusionStrength;
#endif
#endif


#ifdef UNITY_UI_CLIP_RECT
float _specularAntiAliasingVariance;
float _specularAntiAliasingThreshold;
#endif


float _Reflectance;





#include "VRS_Lighting.cginc"


#endif


#include "VRS_Vert.cginc"
#include "VRS_Frag.cginc"

