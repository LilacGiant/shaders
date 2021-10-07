#define DECLARE_TEX2D_CUSTOM_SAMPLER(tex) SamplerState sampler##tex; Texture2D tex; float4 tex##_ST
#define DECLARE_TEX2D_CUSTOM(tex)                                    Texture2D tex; float4 tex##_ST

DECLARE_TEX2D_CUSTOM_SAMPLER(_MainTex);
float4 _Color;

DECLARE_TEX2D_CUSTOM(_MetallicGlossMap);
float _Metallic;
float _Glossiness;
float _Occlusion;

DECLARE_TEX2D_CUSTOM_SAMPLER(_BumpMap);
float _BumpScale;

float _specularAntiAliasingVariance;
float _specularAntiAliasingThreshold;
float _Reflectance;
float4 _FresnelColor;