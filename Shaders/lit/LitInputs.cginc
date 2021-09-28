#if (PROP_MODE!=0) || !defined(OPTIMIZER_ENABLED)
    #define ENABLE_TRANSPARENCY
#endif

#if !defined(OPTIMIZER_ENABLED) // defined if texture gets used
    #define PROP_BUMPMAP
    #define PROP_METALLICMAP
    #define PROP_SMOOTHNESSMAP
    #define PROP_OCCLUSIONMAP
    #define PROP_EMISSIONMAP
    #define PROP_METALLICGLOSSMAP
    #define PROP_DETAILMAP
    #define PROP_ALEMISSIONMAP
    #define PROP_ENABLEVERTEXCOLOR
    #define PROP_ANISOTROPYMAP
    #define PROP_DISPLACEMENTMASK
    #define PROP_DISPLACEMENTNOISE
    #define NEEDS_UV2
#endif

#define NEEDS_UV1
#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META) || (PROP_MAINTEXUV==2) || (PROP_METALLICGLOSSMAPUV==2) || (PROP_SMOOTHNESSMAPUV==2) || (PROP_METALLICMAPUV==2) || (PROP_OCCLUSIONMAPUV==2) || (PROP_BUMPMAPUV==2) || (PROP_EMISSIONMAPUV==2) || (PROP_DETAILMAPUV==2) || (PROP_DISPLACEMENTMASKUV==2)
    #define NEEDS_UV2
#endif

#if defined(PROP_DETAILMAP) || (PROP_ENABLEANISOTROPY==1)
    #define PROP_BUMPMAP
#endif

#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
    #define USE_FOG
#endif


#if !defined(UNITY_PASS_FORWARDBASE) && !defined(UNITY_PASS_META)
    #if defined(ENABLE_AUDIOLINK)
        #undef ENABLE_AUDIOLINK
    #endif
#endif

#if defined(ENABLE_AUDIOLINK)
//#if_EnableAudioLink
    #include "AudioLink.cginc"  
#endif



static float2 uvs[3];
uniform half _Cutoff;
uniform half _Mode;
uniform half _AlphaToMask;

uniform float _SpecularOcclusionSensitivity;
uniform float3 _SpecularDirection;

UNITY_DECLARE_TEX2D(_MainTex);
uniform float4 _MainTex_TexelSize;
uniform float _MainTexUV;
uniform float _SuperSamplingBias;
uniform float4 _MainTex_ST;
uniform half4 _Color;
uniform half _Saturation;
uniform half _EnableVertexColor;


uniform float _NormalMapOrientation;
UNITY_DECLARE_TEX2D(_BumpMap);
uniform float _BumpMapUV;
uniform float4 _BumpMap_ST;
uniform half _BumpScale;
uniform int _HemiOctahedron;

#ifndef ENABLE_PACKED_MODE
UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicMap);
uniform float _MetallicMapUV;
uniform float4 _MetallicMap_ST;
#endif
uniform half _Metallic;

#ifndef ENABLE_PACKED_MODE

UNITY_DECLARE_TEX2D_NOSAMPLER(_SmoothnessMap);
uniform float _SmoothnessMapUV;
uniform float4 _SmoothnessMap_ST;

#endif
uniform float _GlossinessInvert;

uniform half _Glossiness;

#ifndef ENABLE_PACKED_MODE
UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
uniform float _OcclusionMapUV;
uniform float4 _OcclusionMap_ST;
#endif
uniform half _Occlusion;


UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicGlossMap);
uniform float _MetallicGlossMapUV;
uniform float4 _MetallicGlossMap_ST;

uniform int _GSAA;
uniform half _specularAntiAliasingVariance;
uniform half _specularAntiAliasingThreshold;

uniform half4 _FresnelColor;
uniform float3 _SheenColor;
uniform float _SheenRoughness;

uniform half _GetDominantLight;

uniform half _Reflectance;
uniform int _EnableAnisotropy;
uniform half _Anisotropy;
UNITY_DECLARE_TEX2D_NOSAMPLER(_AnisotropyMap);
uniform float4 _AnisotropyMap_ST;


uniform half _LightmapMultiplier;
uniform half _SpecularOcclusion;

uniform half _EnableEmission;
UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
uniform float _EmissionMapUV;
uniform float4 _EmissionMap_ST;
uniform half3 _EmissionColor;



#ifdef ENABLE_PARALLAX
UNITY_DECLARE_TEX2D_NOSAMPLER(_ParallaxMap);
uniform float4 _ParallaxMap_ST;
uniform float _ParallaxSteps;
uniform float _ParallaxOffset;
uniform float _Parallax;
#endif

UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMap);
uniform float4 _DetailMap_ST;
uniform half _DetailMapUV;
uniform half _DetailAlbedoScale;
uniform half _DetailNormalScale;
uniform half _DetailSmoothnessScale;

#ifdef ENABLE_DISPLACEMENT
UNITY_DECLARE_TEX2D(_DisplacementMask);
uniform int _DisplacementMaskUV;
uniform float _DisplacementIntensity;

UNITY_DECLARE_TEX2D(_DisplacementNoise);
uniform int _RandomizePosition;
uniform float2 _DisplacementNoisePan;

#endif


//sampler2D_float _CameraDepthTexture;
//float4 _CameraDepthTexture_TexelSize;

uniform float _LightProbeMethod;

uniform float _FlatShading;
float bakeryLightmapMode;

struct Lighting
{
    half3 color;
    float3 direction;
    half NoL;
    half LoH;
    float3 halfVector;
    half attenuation;
    half3 indirectDominantColor;
    half3 finalLight;
    half3 indirectDiffuse;
    half3 directSpecular;
    half3 indirectSpecular;
    float4 bakedDir;
};
static Lighting light;

struct Surface
{
    half4 albedo;
    half metallic;
    half oneMinusMetallic;
    half perceptualRoughness;
    half roughness;
    half occlusion;
    half3 emission;
};
static Surface surface;

struct Pixel
{
    float3 anisotropicT;
    float3 anisotropicB;
    float3 anisotropicDirection;
    float2 parallaxOffset;
    float3 worldPos;
    float3 worldNormal;
};

static Pixel pixel;

#if defined(VERTEXLIGHT_ON) && defined(UNITY_PASS_FORWARDBASE)
struct VertexLightInformation {
    float3 Direction[4];
    float3 ColorFalloff[4];
    float Attenuation[4];
};
static VertexLightInformation vertexLightInformation;
#endif

#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "LitLighting.cginc"

#ifdef UNITY_PASS_META
    #include "UnityMetaPass.cginc"
#endif

#if defined(BAKERY_SH) || defined(BAKERY_RNM) || defined(BAKERY_LMSPEC)
    #ifdef UNITY_PASS_FORWARDBASE
//#if_BAKERY_SH,_BAKERY_RNM
        #include "Bakery.cginc"
    #else
    #undef BAKERY_SH
    #undef BAKERY_RNM
    #undef BAKERY_LMSPEC
    #endif
#endif

#if defined(LOD_FADE_CROSSFADE)
    #if defined(UNITY_PASS_META)
        #undef LOD_FADE_CROSSFADE
    #endif
#endif