#ifndef VRS_PASS
#define VRS_PASS

#pragma exclude_renderers gles


UNITY_DECLARE_TEX2D(_MainTex);
uniform half4 _MainTex_ST;
uniform float4 _Color;

#ifdef _NORMALMAP
uniform UNITY_DECLARE_TEX2D_NOSAMPLER(_BumpMap);
uniform float _BumpScale;
#endif

#if defined(PROP_ENABLEMETALLICMAP) || !defined(OPTIMIZER_ENABLED)
uniform UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicMap);
#endif
uniform float _Metallic;


#if defined(PROP_ENABLEROUGHNESSMAP) || !defined(OPTIMIZER_ENABLED)
uniform UNITY_DECLARE_TEX2D_NOSAMPLER(_RoughnessMap);
#endif
uniform float _Roughness;

#if defined(PROP_ENABLEOCCLUSION) || !defined(OPTIMIZER_ENABLED)
uniform UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
uniform float _OcclusionStrength;
#endif


#ifdef UNITY_UI_CLIP_RECT
uniform float _specularAntiAliasingVariance;
uniform float _specularAntiAliasingThreshold;
#endif


uniform float _Reflectance;





#include "VRS_Lighting.cginc"


#endif


#include "VRS_Vert.cginc"
#include "VRS_Frag.cginc"

