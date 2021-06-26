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

#ifdef _METALLICGLOSSMAP
uniform UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicMap);
#endif
uniform float _Metallic;

#ifdef _SPECGLOSSMAP
uniform UNITY_DECLARE_TEX2D_NOSAMPLER(_RoughnessMap);
#endif
uniform float _Roughness;

#ifdef _DETAIL_MULX2
uniform UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
uniform float _OcclusionStrength;
#endif


#ifdef UNITY_UI_CLIP_RECT
uniform float _specularAntiAliasingVariance;
uniform float _specularAntiAliasingThreshold;
#endif


uniform float _Reflectance;
uniform float _Anisotropy;



uniform float _SpecularOcclusion;


#include "VRS_Lighting.cginc"


#endif


#include "VRS_Vert.cginc"
#include "VRS_Frag.cginc"

