#define DECLARE_TEX2D_CUSTOM_SAMPLER(tex) SamplerState sampler##tex; Texture2D tex; uint tex##_UV; float4 tex##_ST
#define DECLARE_TEX2D_CUSTOM(tex)                                    Texture2D tex; uint tex##_UV; float4 tex##_ST
static SamplerState defaultSampler;

// CBUFFER_START(UnityPerMaterial)

DECLARE_TEX2D_CUSTOM_SAMPLER(_MainTex);
float4 _MainTex_TexelSize;
float _MipScale;
float4 _Color;
float4 _Stochastic_ST;
float _Reflectance;
float _FresnelIntensity;
float3 _FresnelColor;
float _Roughness;
float _Glossiness;
float _Metallic;
float _Occlusion;
float _Saturation;
float _Cutoff;
uint _UseTextureIndex;
float _SpecularOcclusion;

uint _GlossinessInvert;

DECLARE_TEX2D_CUSTOM_SAMPLER(_BumpMap);
float _BumpScale;
uint _NormalMapOrientation;
uint _HemiOctahedron;

float _GSAA;
float _GSAANormal;
float _specularAntiAliasingVariance;
float _specularAntiAliasingThreshold;

DECLARE_TEX2D_CUSTOM(_MetallicGlossMap);
DECLARE_TEX2D_CUSTOM(_MetallicMap);
DECLARE_TEX2D_CUSTOM(_SmoothnessMap);
DECLARE_TEX2D_CUSTOM(_OcclusionMap);

DECLARE_TEX2D_CUSTOM(_EmissionMap);
uint _EmissionMultBase;
float3 _EmissionColor;

DECLARE_TEX2D_CUSTOM(_DetailMap);
DECLARE_TEX2D_CUSTOM(_DetailAlbedoMap);
DECLARE_TEX2D_CUSTOM(_DetailMaskMap);
DECLARE_TEX2D_CUSTOM(_DetailNormalMap);
float _DetailMaskScale;
float _DetailPacked;
float _DetailAlbedoScale;
float _DetailNormalScale;
float _DetailSmoothnessScale;

DECLARE_TEX2D_CUSTOM(_ParallaxMap);
float _ParallaxSteps;
float _ParallaxOffset;
float _Parallax;


float _Anisotropy;
DECLARE_TEX2D_CUSTOM(_AnisotropyMap);

#ifndef TEXTUREARRAY
    #undef TEXTUREARRAYMASK
    #undef TEXTUREARRAYBUMP
#endif

#if defined(TEXTUREARRAYMASK) || defined(TEXTUREARRAYBUMP)
    #ifndef TEXTUREARRAY
        #define TEXTUREARRAY
    #endif
#endif

#if defined(TEXTUREARRAY)
#undef PARALLAX
UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
float4 _MainTexArray_TexelSize;
UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_MetallicGlossMapArray);
UNITY_DECLARE_TEX2DARRAY_NOSAMPLER(_BumpMapArray);
float _ArrayCount;
#endif


// CBUFFER_END


UNITY_INSTANCING_BUFFER_START(Props)
    #if defined (TEXTUREARRAYINSTANCED)
        UNITY_DEFINE_INSTANCED_PROP(float, _TextureIndex)
    #endif
UNITY_INSTANCING_BUFFER_END(Props)


#if !defined(OPTIMIZER_ENABLED) // defined if texture gets used
    #define PROP_BUMPMAP
    #define PROP_METALLICMAP
    #define PROP_SMOOTHNESSMAP
    #define PROP_OCCLUSIONMAP
    #define PROP_EMISSIONMAP
    #define PROP_METALLICGLOSSMAP
    #define PROP_ANISOTROPYMAP
    #define PROP_DETAILMAP
    #define PROP_PARALLAXMAP
    #define PROP_ALEMISSIONMAP
    #define PROP_DETAILALBEDOMAP
    #define PROP_DETAILMASKMAP
    #define PROP_DETAILNORMALMAP
#endif

#if defined(STOCHASTIC)
    #undef PARALLAX
#endif
#if defined(PARALLAX)
    #undef STOCHASTIC
#endif

static float2 parallaxOffset;
static float textureIndex;
static float4 defaultTexelSize;

#if defined(VERTEXLIGHT_ON) && defined(UNITY_PASS_FORWARDBASE)
struct VertexLightInformation {
    float3 Direction[4];
    float3 ColorFalloff[4];
    float Attenuation[4];
};
static VertexLightInformation vertexLightInformation;
#endif

// #define FLATSHADING

#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2) 
    #define NEED_FOG
#endif

#define NEED_UV2

#if defined(ANISOTROPY)
    #define CALC_TANGENT_BITANGENT
#endif

#ifdef UNITY_PASS_META
    #include "UnityMetaPass.cginc"
#endif

#if defined(OPTIMIZER_ENABLED)
    #if (PROP_DETAILPACKED == 0)
        #undef PROP_DETAILMAP
    #endif
#endif

#if defined(PARALLAX)
    #define NEED_PARALLAX_DIR
#endif

#if defined(LIGHTMAP_SHADOW_MIXING) && defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) && defined(LIGHTMAP_ON)
    #define NEED_SCREEN_POS
#endif

#if !defined(LIGHTMAP_ON) || !defined(UNITY_PASS_FORWARDBASE)
#undef BAKERY_SH
#undef BAKERY_RNM
#endif

float bakeryLightmapMode;
#if defined(BAKERY_SH) || defined(BAKERY_RNM)
    #ifdef BAKERY_SH
    #define BAKERY_SHNONLINEAR
    #endif
    #ifdef BAKEDSPECULAR
    #define _BAKERY_LMSPEC
    #define BAKERY_LMSPEC
    #define NEED_PARALLAX_DIR

    #endif

    #include "Bakery.cginc"
#endif

#ifdef ENABLE_AUDIOLINK
    #include "AudioLink.cginc"
#endif
