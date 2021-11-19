#define DECLARE_TEX2D_CUSTOM_SAMPLER(tex) SamplerState sampler##tex; Texture2D tex; uint tex##_UV; float4 tex##_ST; float4 tex##_TexelSize
#define DECLARE_TEX2D_CUSTOM(tex)                                    Texture2D tex; uint tex##_UV; float4 tex##_ST; float4 tex##_TexelSize

static SamplerState defaultSampler;
static float2 parallaxOffset;
static float textureIndex;


DECLARE_TEX2D_CUSTOM_SAMPLER(_MainTex);
float4 _Color;
float _Saturation;
float _Cutoff;
bool _AlphaToMask;

DECLARE_TEX2D_CUSTOM_SAMPLER(_BumpMap);
float _BumpScale;
bool _NormalMapOrientation;
bool _HemiOctahedron;

bool _GSAA;
float _GSAANormal;
float _specularAntiAliasingVariance;
float _specularAntiAliasingThreshold;

DECLARE_TEX2D_CUSTOM(_MetallicGlossMap);
DECLARE_TEX2D_CUSTOM(_MetallicMap);
DECLARE_TEX2D_CUSTOM(_SmoothnessMap);
DECLARE_TEX2D_CUSTOM(_OcclusionMap);
float _FresnelIntensity;
float3 _FresnelColor;
float _Glossiness;
float _Metallic;
float _Occlusion;
float _Reflectance;
float _SpecularOcclusion;
bool _GlossinessInvert;

DECLARE_TEX2D_CUSTOM(_EmissionMap);
bool _EmissionMultBase;
float3 _EmissionColor;

DECLARE_TEX2D_CUSTOM(_DetailMap);
DECLARE_TEX2D_CUSTOM(_DetailAlbedoMap);
DECLARE_TEX2D_CUSTOM(_DetailMaskMap);
DECLARE_TEX2D_CUSTOM(_DetailNormalMap);
bool _DetailPacked;
float _DetailMaskScale;
float _DetailAlbedoScale;
float _DetailNormalScale;
float _DetailSmoothnessScale;

DECLARE_TEX2D_CUSTOM(_ParallaxMap);
float _ParallaxSteps;
float _ParallaxOffset;
float _Parallax;

DECLARE_TEX2D_CUSTOM(_AnisotropyMap);
float _Anisotropy;

UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_MetallicGlossMapArray);
UNITY_DECLARE_TEX2DARRAY(_BumpMapArray);
float4 _MainTexArray_TexelSize;
float4 _MetallicGlossMapArray_TexelSize;
float4 _BumpMapArray_TexelSize;

float bakeryLightmapMode;


UNITY_INSTANCING_BUFFER_START(Props)
    #if defined (TEXTUREARRAYINSTANCED)
        UNITY_DEFINE_INSTANCED_PROP(float, _TextureIndex)
    #endif
UNITY_INSTANCING_BUFFER_END(Props)

#include "SurfaceData.cginc"
#include "Defines.cginc"