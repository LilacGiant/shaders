#define DECLARE_TEX2D_CUSTOM_SAMPLER(tex) SamplerState sampler##tex; Texture2D tex; uint tex##_UV; float4 tex##_ST
#define DECLARE_TEX2D_CUSTOM(tex)                                    Texture2D tex; uint tex##_UV; float4 tex##_ST


CBUFFER_START(UnityPerMaterial)

DECLARE_TEX2D_CUSTOM_SAMPLER(_MainTex);
float4 _Color;





CBUFFER_END


UNITY_INSTANCING_BUFFER_START(Props)
    //UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
UNITY_INSTANCING_BUFFER_END(Props)


static float2 parallaxOffset;

#define NEED_FOG (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))

#define NEED_UV2



#ifdef UNITY_PASS_FORWARDBASE
    #define NEED_TANGENT (defined(REFLECTIONS) || defined(SPECULAR_HIGHLIGHTS) || defined(PROP_BUMPMAP))
    #define NEED_WORLD_POS
    #define NEED_WORLD_NORMAL
#endif


#ifdef UNITY_PASS_FORWARDADD
    #define NEED_TANGENT (defined(REFLECTIONS) || defined(SPECULAR_HIGHLIGHTS) || defined(PROP_BUMPMAP))
    #define NEED_WORLD_POS
    #define NEED_WORLD_NORMAL
#endif


#ifdef UNITY_PASS_SHADOWCASTER

#endif