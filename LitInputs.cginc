#ifndef LITINPUTS
#define LITINPUTS


uniform float2 uvs[3];
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


UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicMap);
uniform float _MetallicMapUV;
uniform float4 _MetallicMap_ST;
uniform half _Metallic;

UNITY_DECLARE_TEX2D_NOSAMPLER(_SmoothnessMap);
uniform float _SmoothnessMapUV;
uniform float4 _SmoothnessMap_ST;
uniform half _Glossiness;
uniform float _GlossinessInvert;

UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
uniform float _OcclusionMapUV;
uniform float4 _OcclusionMap_ST;
uniform half _Occlusion;


UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicGlossMap);
uniform float _MetallicGlossMapUV;
uniform float4 _MetallicGlossMap_ST;


uniform half _specularAntiAliasingVariance;
uniform half _specularAntiAliasingThreshold;
uniform half4 _MetallicFresnel;
uniform half _AngularGlossiness;


uniform half _Reflectance;
uniform half _ExposureOcclusion;

uniform half _Cutoff;
uniform float _Mode;

uniform half _LightmapMultiplier;
uniform float _SpecularOcclusion;

uniform float _EnableEmission;
UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
uniform float _EmissionMapUV;
uniform float4 _EmissionMap_ST;
uniform half3 _EmissionColor;

uniform float _IridescenceIntensity;
uniform float _EnableIridescence;
UNITY_DECLARE_TEX2D_NOSAMPLER(_IridescenceMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_NoiseMap);

UNITY_DECLARE_TEX2D_NOSAMPLER(_ParallaxMap);
uniform float4 _ParallaxMap_ST;
uniform float _ParallaxSteps;
uniform float _ParallaxOffset;
uniform float _Parallax;

sampler2D_float _CameraDepthTexture;
float4 _CameraDepthTexture_TexelSize;



#if defined(FXAA_LOW) && !defined(OPTIMIZER_ENABLED)
#ifndef SHADER_API_MOBILE
#define SHADER_API_MOBILE
#endif

#define half min16float
#define half2 min16float2
#define half3 min16float3
//#define half4 min16float4 // :unity_developement:
//#define half3x3 min16float3x3
//#define half3x4 min16float3x4
#endif

#define TRANSFORM_MAINTEX(tex,name) (tex.xy * name##_ST.xy * _MainTex_ST.xy + name##_ST.zw + _MainTex_ST.zw)
#pragma exclude_renderers gles
#ifdef UNITY_UI_CLIP_RECT
#define ENABLE_GSAA
#endif

#ifdef _DETAIL_MULX2
#define ENABLE_BICUBIC_LIGHTMAP
#endif

#if (PROP_ENABLENORMALMAP==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_NORMALMAP
#endif

#ifdef UNITY_UI_ALPHACLIP
#define ENABLE_PACKED_MODE
#endif

#if (PROP_ENABLEMETALLICMAP==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_METALLICMAP
#endif

#if (PROP_ENABLEROUGHNESSMAP==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_SMOOTHNESSMAP
#endif

#if (PROP_ENABLEOCCLUSION==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_OCCLUSIONMAP
#endif

#ifdef UNITY_UI_CLIP_RECT
#define ENABLE_GSAA
#endif

#if (PROP_MODE!=0) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_TRANSPARENCY
#endif

#if (PROP_ENABLEEMISSION==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_EMISSION
#endif

#if (PROP_ENABLEVERTEXCOLOR==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_VERTEXCOLOR
#endif





#endif