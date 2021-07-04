#ifndef VRS_PASS
#define VRS_PASS

#pragma exclude_renderers gles

#ifdef UNITY_UI_CLIP_RECT
#define ENABLE_GSAA
#endif



UNITY_DECLARE_TEX2D(_MainTex);
float4 _MainTex_ST;
float4 _Color;

#ifdef _NORMALMAP
UNITY_DECLARE_TEX2D(_BumpMap);
float4 _BumpMap_ST;
float _BumpScale;
#endif

#if (PROP_ENABLEMETALLICMAP==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_METALLICMAP
Texture2D _MetallicMap;
#endif
float _Metallic;


#if (PROP_ENABLEROUGHNESSMAP==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_ROUGHNESSMAP
Texture2D _RoughnessMap;
#endif
float _Roughness;

#if (PROP_ENABLEOCCLUSION==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_OCCLUSIONMAP
Texture2D _OcclusionMap;
float _OcclusionStrength;
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

