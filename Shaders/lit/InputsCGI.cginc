#define DECLARE_TEX2D_CUSTOM_SAMPLER(tex) SamplerState sampler##tex; Texture2D tex
#define DECLARE_TEX2D_CUSTOM(tex)                                    Texture2D tex

#define DECLARE_TEX2D_CUSTOM_PROPS(tex)         uint tex##_UV; float4 tex##_ST; float4 tex##_TexelSize

static SamplerState defaultSampler;
static float2 parallaxOffset;
static float textureIndex;

DECLARE_TEX2D_CUSTOM_SAMPLER(_MainTex);
DECLARE_TEX2D_CUSTOM_SAMPLER(_BumpMap);
DECLARE_TEX2D_CUSTOM(_MetallicGlossMap);
DECLARE_TEX2D_CUSTOM(_MetallicMap);
DECLARE_TEX2D_CUSTOM(_SmoothnessMap);
DECLARE_TEX2D_CUSTOM(_OcclusionMap);
DECLARE_TEX2D_CUSTOM(_EmissionMap);
DECLARE_TEX2D_CUSTOM(_DetailMap);
DECLARE_TEX2D_CUSTOM(_DetailAlbedoMap);
DECLARE_TEX2D_CUSTOM(_DetailMaskMap);
DECLARE_TEX2D_CUSTOM(_DetailNormalMap);
DECLARE_TEX2D_CUSTOM(_ParallaxMap);
UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_MetallicGlossMapArray);
UNITY_DECLARE_TEX2DARRAY(_BumpMapArray);
DECLARE_TEX2D_CUSTOM(_AnisotropyMap);

sampler3D _OcclusionProbes;

#ifndef PROPERTIES_DEFINED

float4 _Color;
float _Saturation;
float _Cutoff;
float _AlphaToMask;

float _EnableOcclusionProbes;
float4x4 _OcclusionProbesWorldToLocal;

float _BumpScale;
float _NormalMapOrientation;
float _HemiOctahedron;

float _GSAA;
float _GSAANormal;
float _specularAntiAliasingVariance;
float _specularAntiAliasingThreshold;


float _FresnelIntensity;
float3 _FresnelColor;
float _Glossiness;
float _Metallic;
float _Occlusion;
float _GlossinessMin;
float _MetallicMin;
float _OcclusionMin;
float _Reflectance;
float _SpecularOcclusion;
float _GlossinessInvert;
float _SpecularIntensity;

float _EmissionMultBase;
float3 _EmissionColor;


float _DetailPacked;
float _DetailMaskScale;
float _DetailAlbedoScale;
float _DetailNormalScale;
float _DetailSmoothnessScale;

float _ParallaxSteps;
float _ParallaxOffset;
float _Parallax;

float _Anisotropy;


float4 _MainTexArray_TexelSize;
float4 _MetallicGlossMapArray_TexelSize;
float4 _BumpMapArray_TexelSize;

float bakeryLightmapMode;
DECLARE_TEX2D_CUSTOM_PROPS(_MainTex);
DECLARE_TEX2D_CUSTOM_PROPS(_BumpMap);
DECLARE_TEX2D_CUSTOM_PROPS(_MetallicGlossMap);
DECLARE_TEX2D_CUSTOM_PROPS(_MetallicMap);
DECLARE_TEX2D_CUSTOM_PROPS(_SmoothnessMap);
DECLARE_TEX2D_CUSTOM_PROPS(_OcclusionMap);
DECLARE_TEX2D_CUSTOM_PROPS(_EmissionMap);
DECLARE_TEX2D_CUSTOM_PROPS(_DetailMap);
DECLARE_TEX2D_CUSTOM_PROPS(_DetailAlbedoMap);
DECLARE_TEX2D_CUSTOM_PROPS(_DetailMaskMap);
DECLARE_TEX2D_CUSTOM_PROPS(_DetailNormalMap);
DECLARE_TEX2D_CUSTOM_PROPS(_ParallaxMap);
DECLARE_TEX2D_CUSTOM_PROPS(_AnisotropyMap);

#endif

UNITY_INSTANCING_BUFFER_START(Props)
    #if defined (TEXTUREARRAYINSTANCED)
        UNITY_DEFINE_INSTANCED_PROP(float, _TextureIndex)
    #endif
UNITY_INSTANCING_BUFFER_END(Props)

#include "SurfaceData.cginc"
#include "Defines.cginc"
