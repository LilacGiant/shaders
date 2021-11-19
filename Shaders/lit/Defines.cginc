#define grayscaleVec half3(0.2125, 0.7154, 0.0721)
#define TAU 6.28318530718
#define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))


#if !defined(OPTIMIZER_ENABLED)
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

#if defined(TEXTUREARRAY)
    #undef PARALLAX
#endif

#if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_META) || defined(UNITY_PASS_FORWARDADD)
    #define NEED_TANGENT_BITANGENT
    #define NEED_WORLD_POS
    #define NEED_WORLD_NORMAL
#endif

#if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2) 
    #define NEED_FOG
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