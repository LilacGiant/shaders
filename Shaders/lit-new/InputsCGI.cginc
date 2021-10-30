#define DECLARE_TEX2D_CUSTOM_SAMPLER(tex) SamplerState sampler##tex; Texture2D tex; uint tex##_UV; float4 tex##_ST
#define DECLARE_TEX2D_CUSTOM(tex)                                    Texture2D tex; uint tex##_UV; float4 tex##_ST
static SamplerState defaultSampler;

// CBUFFER_START(UnityPerMaterial)

DECLARE_TEX2D_CUSTOM_SAMPLER(_MainTex);
float4 _MainTex_TexelSize;
float _MipScale;
float4 _Color;
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

uint _GSAA;
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
    #define TEXTUREARRAY
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

#ifdef INSTANCING_ON
UNITY_INSTANCING_BUFFER_START(Props)
    #if defined (TEXTUREARRAY)
        UNITY_DEFINE_INSTANCED_PROP(float, _TextureIndex)
    #endif
UNITY_INSTANCING_BUFFER_END(Props)
#endif

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
#endif

static float2 parallaxOffset;
static float textureIndex;
static float4 defaultTexelSize;
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



#ifdef UNITY_PASS_FORWARDBASE
    #define NEED_TANGENT_BITANGENT
    #define NEED_WORLD_POS
    #define NEED_WORLD_NORMAL
    #if defined(PARALLAX)
        #define NEED_PARALLAX_DIR
    #endif
    #if defined(VERTEXCOLOR)
        #define NEED_VERTEX_COLOR
    #endif
#endif

#ifdef UNITY_PASS_FORWARDADD
    #define NEED_TANGENT_BITANGENT
    #define NEED_WORLD_POS
    #define NEED_WORLD_NORMAL
    #if defined(PARALLAX)
        #define NEED_PARALLAX_DIR
    #endif
    #if defined(VERTEXCOLOR)
        #define NEED_VERTEX_COLOR
    #endif
    #undef REFLECTIONS
    #undef EMISSION
    #undef BICUBIC_LIGHTMAP
    #undef BAKEDSPECULAR
    #undef BAKERY_SH
    #undef BAKERY_SHNONLINEAR
    #undef BAKERY_RNM
    #if defined(LIGHTMAP_SHADOW_MIXING) && defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) && defined(LIGHTMAP_ON)
        #define NEED_SCREEN_POS
    #endif
#endif


#ifdef UNITY_PASS_SHADOWCASTER
    #undef REFLECTIONS
    #if defined(VERTEXCOLOR)
        #define NEED_VERTEX_COLOR
    #endif
    #undef EMISSION
    #undef BICUBIC_LIGHTMAP
    #undef PARALLAX
    #undef BAKEDSPECULAR
    #undef BAKERY_SH
    #undef BAKERY_SHNONLINEAR
    #undef BAKERY_RNM
    #undef ANISOTROPY
    #if defined(LIGHTMAP_SHADOW_MIXING) && defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) && defined(LIGHTMAP_ON)
        #define NEED_SCREEN_POS
    #endif
#endif

#ifdef UNITY_PASS_META
    #define NEED_TANGENT_BITANGENT
    #define NEED_WORLD_POS
    #define NEED_WORLD_NORMAL
    #if defined(PARALLAX)
        #define NEED_PARALLAX_DIR
    #endif
    #include "UnityMetaPass.cginc"
#endif