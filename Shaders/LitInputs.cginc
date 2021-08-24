#ifndef LITINPUTS
#define LITINPUTS


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
uniform half _TriplanarBlend;


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
uniform half _EnableVertexColorMask;


uniform half _specularAntiAliasingVariance;
uniform half _specularAntiAliasingThreshold;
uniform half4 _FresnelColor;
uniform half _AngularGlossiness;
uniform float _GetDominantLight;

uniform half _Reflectance;
uniform half _ExposureOcclusion;
uniform half _Anisotropy;


uniform half _LightmapMultiplier;
uniform float _SpecularOcclusion;

uniform float _EnableEmission;
UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);
uniform float _EmissionMapUV;
uniform float4 _EmissionMap_ST;
uniform half3 _EmissionColor;


UNITY_DECLARE_TEX2D_NOSAMPLER(_ParallaxMap);
uniform float4 _ParallaxMap_ST;
uniform float _ParallaxSteps;
uniform float _ParallaxOffset;
uniform float _Parallax;

//sampler2D_float _CameraDepthTexture;
//float4 _CameraDepthTexture_TexelSize;

uniform float _LightProbeMethod;

uniform float _TonemappingMode;
uniform half _Contribution;


UNITY_DECLARE_TEX2D_NOSAMPLER(_MatCap);
uniform half _MatCapReplace;


UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMap);
uniform float4 _DetailMap_ST;
uniform half _DetailMapUV;





// ----------------- defines -----------------

#if (PROP_MODE!=0) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_TRANSPARENCY
#endif

#if (PROP_ENABLEVERTEXCOLOR==1) || (PROP_ENABLEVERTEXCOLORMASK==1) || !defined(OPTIMIZER_ENABLED)
#define ENABLE_VERTEXCOLOR
#endif

#if !defined(OPTIMIZER_ENABLED) // defined if texture gets used
    #define PROP_BUMPMAP
    #define PROP_METALLICMAP
    #define PROP_SMOOTHNESSMAP
    #define PROP_OCCLUSIONMAP
    #define PROP_EMISSIONMAP
    #define PROP_METALLICGLOSSMAP
    #define PROP_DETAILMAP
#endif

// ----------------- defines -----------------

#endif