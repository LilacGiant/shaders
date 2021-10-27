#define DECLARE_TEX2D_CUSTOM_SAMPLER(tex) SamplerState sampler##tex; Texture2D tex; uint tex##_UV; float4 tex##_ST
#define DECLARE_TEX2D_CUSTOM(tex)                                    Texture2D tex; uint tex##_UV; float4 tex##_ST
static SamplerState defaultSampler;

// CBUFFER_START(UnityPerMaterial)

DECLARE_TEX2D_CUSTOM_SAMPLER(_MainTex);
float4 _Color;
float _Reflectance;
float _FresnelIntensity;
float3 _FresnelColor;
float _Roughness;
float _Glossiness;
float _Metallic;
float _Occlusion;

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

#ifdef PARALLAX
DECLARE_TEX2D_CUSTOM(_ParallaxMap);
float _ParallaxSteps;
float _ParallaxOffset;
float _Parallax;
#endif

float _Anisotropy;
DECLARE_TEX2D_CUSTOM(_AnisotropyMap);

#if defined (TEXTUREARRAY)
UNITY_DECLARE_TEX2DARRAY(_MainTexArray);
float _TriplanarBlend;
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
#endif

static float2 parallaxOffset;
static float textureIndex;

#define NEED_FOG (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))

#define NEED_UV2

#define CALC_TANGENT_BITANGENT (defined(ANISOTROPY))

#ifdef UNITY_PASS_FORWARDBASE
    #define NEED_TANGENT_BITANGENT
    #define NEED_WORLD_POS
    #define NEED_WORLD_NORMAL
    #define NEED_PARALLAX_DIR (defined(PARALLAX))
#endif


#ifdef UNITY_PASS_FORWARDADD
    #define NEED_TANGENT_BITANGENT
    #define NEED_WORLD_POS
    #define NEED_WORLD_NORMAL
    #define NEED_PARALLAX_DIR (defined(PARALLAX))
    #undef REFLECTIONS
    #undef EMISSION
    #undef BICUBIC_LIGHTMAP
    #undef BAKEDSPECULAR
    #undef BAKERY_SH
    #undef BAKERY_SHNONLINEAR
    #undef BAKERY_RNM
#endif


#ifdef UNITY_PASS_SHADOWCASTER
    #undef REFLECTIONS
    #define NEED_WORLD_POS (defined(_WORKFLOW_TRIPLANAR))
    #define NEED_WORLD_NORMAL (defined(_WORKFLOW_TRIPLANAR))
    #undef EMISSION
    #undef BICUBIC_LIGHTMAP
    #undef PARALLAX
    #undef BAKEDSPECULAR
    #undef BAKERY_SH
    #undef BAKERY_SHNONLINEAR
    #undef BAKERY_RNM
    #undef ANISOTROPY
#endif