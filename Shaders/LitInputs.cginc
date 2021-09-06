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
#endif


#ifdef SHADER_API_MOBILE
    #undef ENABLE_PARALLAX
    #undef PROP_DETAILMAP
    #undef ENABLE_AUDIOLINK
#endif

#if defined(PROP_DETAILMAP)
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
    #include "AudioLink.cginc"  
#endif





uniform float2 uvs[4];
uniform half _Cutoff;
uniform half _Mode;
uniform half _AlphaToMask;

UNITY_DECLARE_TEX2D(_MainTex);
uniform float _MainTexUV;
uniform float4 _MainTex_ST;
uniform half4 _Color;
uniform half _Saturation;
uniform half _EnableVertexColor;


uniform float _EnableNormalMap;
uniform float _NormalMapOrientation;
UNITY_DECLARE_TEX2D(_BumpMap);
uniform float _BumpMapUV;
uniform float4 _BumpMap_ST;
uniform half _BumpScale;

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
uniform half _EnableVertexColorMask;


uniform half _specularAntiAliasingVariance;
uniform half _specularAntiAliasingThreshold;
uniform half4 _FresnelColor;
uniform half _AngularGlossiness;
uniform half _GetDominantLight;

uniform half _Reflectance;
uniform half _ExposureOcclusion;
uniform half _Anisotropy;


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

//sampler2D_float _CameraDepthTexture;
//float4 _CameraDepthTexture_TexelSize;

uniform float _LightProbeMethod;

#ifdef ENABLE_REFRACTION
uniform half _Refraction;
#endif


UNITY_DECLARE_TEX2D_NOSAMPLER(_MatCap);
uniform half _MatCapReplace;


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
