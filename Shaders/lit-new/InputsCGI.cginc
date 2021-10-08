
float _Cutoff;

Texture2D _MainTex;
SamplerState sampler_MainTex;
float4 _MainTex_ST;
float4 _Color;
float _BaseSaturation;

Texture2D _MetallicGlossMap;
float _Metallic;
float _Glossiness;
float _Occlusion;

Texture2D _BumpMap;
SamplerState sampler_BumpMap;
float _BumpScale;

float _specularAntiAliasingVariance;
float _specularAntiAliasingThreshold;
float _Reflectance;
float4 _FresnelColor;

Texture2D _EmissionMap;
float3 _EmissionColor;

Texture2D _DetailMap;
float4 _DetailMap_ST;
float _DetailAlbedoScale;
float _DetailNormalScale;
float _DetailSmoothnessScale;