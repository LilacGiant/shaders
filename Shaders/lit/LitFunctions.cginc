half calcAlpha(half alpha)
{
    UNITY_BRANCH
    if(_Mode == 1)
    {
        switch(_AlphaToMask)
        {
            case 0:
                clip(alpha - _Cutoff);
                break;
            case 2:
                alpha = (alpha - _Cutoff) / max(fwidth(alpha), 0.0001) + 0.5;
                break;
        }
    }

    return alpha;
}

void initNormalMap(half4 normalMap, inout half3 bitangent, inout half3 tangent, inout half3 normal, half4 detailNormalMap, inout float3 tangentNormal)
{
    //normalMap.g = _NormalMapOrientation ? 1-normalMap.g : normalMap.g;

    tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);

    #if defined(PROP_DETAILMAP)
        detailNormalMap.g = 1-detailNormalMap.g;
        half3 detailNormal = UnpackScaleNormal(detailNormalMap, _DetailNormalScale);
        tangentNormal = BlendNormals(tangentNormal, detailNormal);
    #endif

    tangentNormal.g *= _NormalMapOrientation ? 1 : -1;

    half3 calcedNormal = normalize
    (
		tangentNormal.x * tangent +
		tangentNormal.y * bitangent +
		tangentNormal.z * normal
    );


    normal = calcedNormal;
    tangent = cross(normal, bitangent);
    bitangent = cross(normal, tangent);    
}


bool isInMirror()
{
    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

half BlendMode_Overlay(half base, half blend)
{
	return (base <= 0.5) ? 2*base*blend : 1 - 2*(1-base)*(1-blend);
}

half3 BlendMode_Overlay(half3 base, half3 blend)
{
    return half3(   BlendMode_Overlay(base.r, blend.r),
                    BlendMode_Overlay(base.g, blend.g),
                    BlendMode_Overlay(base.b, blend.b));
}

float2 Rotate(float2 coords, float rot){
	rot *= (UNITY_PI/180.0);
	float sinVal = sin(rot);
	float cosX = cos(rot);
	float2x2 mat = float2x2(cosX, -sinVal, sinVal, cosX);
	mat = ((mat*0.5)+0.5)*2-1;
	return mul(coords, mat);
}


#define TRANSFORM(uv, tileOffset) (uv.xy * tileOffset.xy + tileOffset.zw + parallaxOffset)
#define TRANSFORMTEX(uv, tileOffset, transformTex) (uv.xy * tileOffset.xy * transformTex.xy + tileOffset.zw + transformTex.zw + parallaxOffset)
#define TRANSFORMTEXNOOFFSET(uv, tileOffset, transformTex) (uv.xy * tileOffset.xy * transformTex.xy + tileOffset.zw + transformTex.zw + parallaxOffset)

#define MAIN_TEX(tex, sampl, texUV, texST) (tex.Sample(sampl, TRANSFORM(texUV.xy, texST)))
#define NOSAMPLER_TEX(tex, texUV, texST, mainST) (tex.Sample(sampler_MainTex, TRANSFORMTEX(texUV.xy, texST, mainST)))


#ifdef ENABLE_PARALLAX
float3 CalculateTangentViewDir(float3 tangentViewDir)
{
    tangentViewDir = Unity_SafeNormalize(tangentViewDir);
    tangentViewDir.xy /= (tangentViewDir.z + 0.42);
	return tangentViewDir;
}

// uwu https://github.com/MochiesCode/Mochies-Unity-Shaders/blob/7d48f101d04dac11bd4702586ee838ca669f426b/Mochie/Standard%20Shader/MochieStandardParallax.cginc#L13
float2 ParallaxOffsetMultiStep(float surfaceHeight, float strength, float2 uv, float3 tangentViewDir)
{
    float2 uvOffset = 0;
	float2 prevUVOffset = 0;
	float stepSize = 1.0/_ParallaxSteps;
	float stepHeight = 1;
	float2 uvDelta = tangentViewDir.xy * (stepSize * strength);
	float prevStepHeight = stepHeight;
	float prevSurfaceHeight = surfaceHeight;

    [unroll(50)]
    for (int j = 1; j <= _ParallaxSteps && stepHeight > surfaceHeight; j++){
        prevUVOffset = uvOffset;
        prevStepHeight = stepHeight;
        prevSurfaceHeight = surfaceHeight;
        uvOffset -= uvDelta;
        stepHeight -= stepSize;
        surfaceHeight = _ParallaxMap.Sample(sampler_MainTex, (uv.xy * _MainTex_ST.xy + _MainTex_ST.zw + uvOffset)) + _ParallaxOffset;
    }
    [unroll(3)]
    for (int k = 0; k < 3; k++) {
        uvDelta *= 0.5;
        stepSize *= 0.5;

        if (stepHeight < surfaceHeight) {
            uvOffset += uvDelta;
            stepHeight += stepSize;
        }
        else {
            uvOffset -= uvDelta;
            stepHeight -= stepSize;
        }
        surfaceHeight = _ParallaxMap.Sample(sampler_MainTex, (uv.xy * _MainTex_ST.xy + _MainTex_ST.zw + uvOffset)) + _ParallaxOffset;
    }

    return uvOffset;
}

float2 ParallaxOffset (float3 viewDirForParallax)
{
    viewDirForParallax = CalculateTangentViewDir(viewDirForParallax);

    float h = _ParallaxMap.Sample(sampler_MainTex, (uvs[_MainTexUV] * _MainTex_ST.xy + _MainTex_ST.zw)) + _ParallaxOffset;
    h = clamp(h, 0, 0.999);
    float2 offset = ParallaxOffsetMultiStep(h, _Parallax, uvs[_MainTexUV], viewDirForParallax);

	return offset;
}
#endif

#ifdef UNITY_PASS_META
float4 getMeta(Surface surface, Lighting light, float alpha)
{
    UnityMetaInput metaInput;
    UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaInput);
    metaInput.Emission = surface.emission;
    metaInput.Albedo = surface.albedo;
    metaInput.SpecularColor = light.directSpecular;
    return float4(UnityMetaFragment(metaInput).rgb, alpha);
}
#endif

void applyEmission(half2 parallaxOffset)
{
    half4 emissionMap = 1;
    #if defined(PROP_EMISSIONMAP)
        emissionMap = _EmissionMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_EmissionMapUV], _EmissionMap_ST, _MainTex_ST));
    #endif

    #if defined(ENABLE_AUDIOLINK)
        float4 alEmissionMap = 1;
        #if defined(PROP_ALEMISSIONMAP)
            alEmissionMap = _ALEmissionMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_EmissionMapUV], _EmissionMap_ST, _MainTex_ST));
        #endif
        
        float alEmissionType = 0;
        float alEmissionBand = _ALEmissionBand;
        float alSmoothing = (1 - _ALSmoothing);
        float alemissionMask = ((alEmissionMap.b * 256) > 1 ) * alEmissionMap.a;
        

        switch(_ALEmissionType)
        {
            case 1:
                alEmissionType = alSmoothing * 15;
                alEmissionBand += ALPASS_FILTEREDAUDIOLINK.y;
                alemissionMask = alEmissionMap.b;
                break;
            case 2:
                alEmissionType = alEmissionMap.b * (128 *  (1 - alSmoothing));
                break;
            case 3:
                alEmissionType = alSmoothing * 15;
                alEmissionBand += ALPASS_FILTEREDAUDIOLINK.y;
                break;
        }

        float alEmissionSample = _ALEmissionType ? AudioLinkLerpMultiline(float2(alEmissionType , alEmissionBand)).r * alemissionMask : 1;
        emissionMap *= alEmissionSample;
    #endif

    surface.emission = _EnableEmission ? emissionMap * pow(_EmissionColor.rgb, 2.2) : 0;
}


void calcDirectSpecular(float3 worldNormal, half3 tangent, half3 bitangent, half3 f0, half NoV)
{
    half NoH = saturate(dot(worldNormal, light.halfVector));
    half roughness = max(surface.perceptualRoughness * surface.perceptualRoughness, 0.002);

    half D = GGXTerm (NoH, roughness);
    half V = V_SmithGGXCorrelated ( NoV,light.NoL, roughness);
    half3 F = F_Schlick(light.LoH, f0);

    float anisotropy = _Anisotropy;
    if(anisotropy != 0) {
        anisotropy *= saturate(5.0 * surface.perceptualRoughness);
        half at = max(roughness * (1.0 + anisotropy), 0.001);
        half ab = max(roughness * (1.0 - anisotropy), 0.001);
        D = D_GGX_Anisotropic(NoH, light.halfVector, tangent, bitangent, at, ab);
    }

    light.directSpecular += max(0, (D * V) * F) * light.finalLight * UNITY_PI;
}

void calcIndirectSpecular(float3 reflDir, float3 worldPos, float3 reflWorldNormal, half3 fresnel, half3 f0)
{
    Unity_GlossyEnvironmentData envData;
    envData.roughness = surface.perceptualRoughness;
    envData.reflUVW = getBoxProjection(
        reflDir, worldPos,
        unity_SpecCube0_ProbePosition,
        unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
    );

    half3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);

    half3 indirectSpecular = probe0;
    

    #if defined(UNITY_SPECCUBE_BLENDING)
        half interpolator = unity_SpecCube0_BoxMin.w;
        UNITY_BRANCH
        if (interpolator < 0.99999)
        {
            envData.reflUVW = getBoxProjection(
                reflDir, worldPos,
                unity_SpecCube1_ProbePosition,
                unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
            );
            half3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, envData);
            indirectSpecular = lerp(probe1, probe0, interpolator);
        }
    #endif

    half horizon = min(1 + dot(reflDir, reflWorldNormal), 1);
    indirectSpecular *= horizon * horizon;

    light.indirectSpecular = indirectSpecular * lerp(fresnel, f0, surface.perceptualRoughness);
}

float3 Unity_NormalReconstructZ_float(float2 In)
{
    float reconstructZ = sqrt(1.0 - saturate(dot(In.xy, In.xy)));
    float3 normalVector = float3(In.x, In.y, reconstructZ);
    return normalize(normalVector);
}

#if !defined(UNITY_PASS_SHADOWCASTER)
void initLighting(v2f i, float3 worldNormal, float3 viewDir, half NoV, float3 tangentNormal)
{
    light.direction = normalize(UnityWorldSpaceLightDir(i.worldPos));
    light.color = _LightColor0.rgb;
    light.halfVector = Unity_SafeNormalize(light.direction + viewDir);
    light.NoL = saturate(dot(worldNormal, light.direction));
    light.LoH = saturate(dot(light.direction, light.halfVector));
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
    light.attenuation = attenuation;
    light.finalLight = (light.NoL * light.attenuation * light.color);
    light.finalLight *= Fd_Burley(surface.perceptualRoughness, NoV, light.NoL, light.LoH);
}
#endif

#if defined(PROP_DETAILMAP)
float4 applyDetailMap(half2 parallaxOffset, float maskMapAlpha)
{
    float4 detailMap = _DetailMap.Sample(sampler_MainTex, TRANSFORM(uvs[_DetailMapUV], _DetailMap_ST));

    float detailMask = maskMapAlpha;
    float detailAlbedo = detailMap.r * 2.0 - 1.0;
    float detailSmoothness = (detailMap.b * 2.0 - 1.0);

    // Goal: we want the detail albedo map to be able to darken down to black and brighten up to white the surface albedo.
    // The scale control the speed of the gradient. We simply remap detailAlbedo from [0..1] to [-1..1] then perform a lerp to black or white
    // with a factor based on speed.
    // For base color we interpolate in sRGB space (approximate here as square) as it get a nicer perceptual gradient

    float albedoDetailSpeed = saturate(abs(detailAlbedo) * _DetailAlbedoScale);
    float3 baseColorOverlay = lerp(sqrt(surface.albedo.rgb), (detailAlbedo < 0.0) ? float3(0.0, 0.0, 0.0) : float3(1.0, 1.0, 1.0), albedoDetailSpeed * albedoDetailSpeed);
    baseColorOverlay *= baseColorOverlay;							   
    // Lerp with details mask
    surface.albedo.rgb = lerp(surface.albedo.rgb, saturate(baseColorOverlay), detailMask);

    float perceptualSmoothness = (1 - surface.perceptualRoughness);
    // See comment for baseColorOverlay
    float smoothnessDetailSpeed = saturate(abs(detailSmoothness) * _DetailSmoothnessScale);
    float smoothnessOverlay = lerp(perceptualSmoothness, (detailSmoothness < 0.0) ? 0.0 : 1.0, smoothnessDetailSpeed);
    // Lerp with details mask
    perceptualSmoothness = lerp(perceptualSmoothness, saturate(smoothnessOverlay), detailMask);

    surface.perceptualRoughness = (1 - perceptualSmoothness);
    return detailMap;
}
#endif

void applySaturation()
{
    half desaturated = dot(surface.albedo.rgb, grayscaleVec);
    surface.albedo.rgb = lerp(desaturated, surface.albedo.rgb, (_Saturation+1));
}

void initSurfaceData(inout half metallicMap, inout half smoothnessMap, inout half occlusionMap, inout half4 maskMap, half2 parallaxOffset)
{
    bool isRoughness = _GlossinessInvert;
    
    #ifndef ENABLE_PACKED_MODE

        #ifdef PROP_METALLICMAP
            metallicMap = NOSAMPLER_TEX(_MetallicMap, uvs[_MetallicMapUV], _MetallicMap_ST, _MainTex_ST);
        #endif

        #ifdef PROP_SMOOTHNESSMAP
            smoothnessMap = NOSAMPLER_TEX(_SmoothnessMap, uvs[_SmoothnessMapUV], _SmoothnessMap_ST, _MainTex_ST);
        #endif

        #ifdef PROP_OCCLUSIONMAP
            occlusionMap = NOSAMPLER_TEX(_OcclusionMap, uvs[_OcclusionMapUV], _OcclusionMap_ST, _MainTex_ST);
        #endif

    #else

        #ifdef PROP_METALLICGLOSSMAP
            maskMap = NOSAMPLER_TEX(_MetallicGlossMap, uvs[_MetallicGlossMapUV], _MetallicGlossMap_ST, _MainTex_ST);
        #endif
        
        metallicMap = maskMap.r;
        smoothnessMap = maskMap.a;
        occlusionMap = maskMap.g;
        isRoughness = 0;
    #endif

    half smoothness = _Glossiness * smoothnessMap;
    surface.perceptualRoughness = isRoughness ? smoothness : 1-smoothness;
    surface.metallic = metallicMap * _Metallic * _Metallic;
    surface.oneMinusMetallic = 1 - surface.metallic;
    surface.occlusion = lerp(1,occlusionMap , _Occlusion);
}

void getMainTex(inout half4 mainTex, half2 parallaxOffset, half4 vertexColor)
{
    mainTex = MAIN_TEX(_MainTex, sampler_MainTex, uvs[_MainTexUV], _MainTex_ST);

    

    surface.albedo = mainTex * _Color;

    #ifdef PROP_ENABLEVERTEXCOLOR
        surface.albedo.rgb *= _EnableVertexColor ? GammaToLinearSpace(vertexColor) : 1;
    #endif
}

void getIndirectDiffuse(float3 worldNormal, float2 parallaxOffset, inout half2 lightmapUV)
{
    #if defined(LIGHTMAP_ON)

        lightmapUV = uvs[1] * unity_LightmapST.xy + unity_LightmapST.zw + parallaxOffset;

        half3 lightMap = tex2DFastBicubicLightmap(lightmapUV) * (_LightmapMultiplier);

        #if defined(DIRLIGHTMAP_COMBINED) && !defined(SHADER_API_MOBILE)
            light.bakedDir = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, lightmapUV);
            lightMap = DecodeDirectionalLightmap(lightMap, light.bakedDir, worldNormal);
        #endif


        #if defined(DYNAMICLIGHTMAP_ON)
            half3 realtimeLightMap = getRealtimeLightmap(uvs[2], worldNormal, parallaxOffset);
            lightMap += realtimeLightMap; 
        #endif
        
        light.indirectDiffuse = lightMap;

    #else
        if(_FlatShading) worldNormal = half3(0,0,0);
        lightmapUV = 0;
        UNITY_BRANCH
        if(_LightProbeMethod == 0)
        {
            light.indirectDiffuse = max(0, ShadeSH9(float4(worldNormal, 1)));
        }
        else
        {
            half3 L0 = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
            light.indirectDiffuse.r = shEvaluateDiffuseL1Geomerics_local(L0.r, unity_SHAr.xyz, worldNormal);
            light.indirectDiffuse.g = shEvaluateDiffuseL1Geomerics_local(L0.g, unity_SHAg.xyz, worldNormal);
            light.indirectDiffuse.b = shEvaluateDiffuseL1Geomerics_local(L0.b, unity_SHAb.xyz, worldNormal);
            light.indirectDiffuse = max(0, light.indirectDiffuse);
        }

    #endif
}

#if defined(VERTEXLIGHT_ON) && defined(UNITY_PASS_FORWARDBASE)
void initVertexLights(float3 worldPos, float3 worldNormal, inout float3 vLight, inout float3 vertexLightColor)
{
    float3 vertexLightData = 0;
    float4 vertexLightAtten = float4(0,0,0,0);
    vertexLightColor = get4VertexLightsColFalloff(vertexLightInformation, worldPos, worldNormal, vertexLightAtten);
    float3 vertexLightDir = getVertexLightsDir(vertexLightInformation, worldPos, vertexLightAtten);
    [unroll(4)]
    for(int i = 0; i < 4; i++)
    {
        vertexLightData += saturate(dot(vertexLightInformation.Direction[i], worldNormal)) * vertexLightInformation.ColorFalloff[i];
    }
    vLight = vertexLightData;
}
#endif

#define MOD3 float3(443.8975,397.2973, 491.1871)
float ditherNoiseFuncLow(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * MOD3 + _Time.y);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

float3 ditherNoiseFuncHigh(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * (MOD3 + _Time.y));
    p3 += dot(p3, p3.yxz + 19.19);
    return frac(float3((p3.x + p3.y)*p3.z, (p3.x + p3.z)*p3.y, (p3.y + p3.z)*p3.x));
}

float3 indirectDiffuseSpecular(float3 worldNormal, float3 viewDir, float3 tangentNormal)
{
    half roughness = max(surface.perceptualRoughness * surface.perceptualRoughness, 0.002);
    float3 dominantDir = 1;
    float3 specColor = 0;

    #if !defined(BAKERY_SH) && !defined(BAKERY_RNM)
        if(bakeryLightmapMode < 2)
        {
            #ifdef DIRLIGHTMAP_COMBINED
                dominantDir = (light.bakedDir.xyz) * 2 - 1;
                specColor = light.indirectDiffuse;
            #endif
            #if defined(LIGHTMAP_ON) && !defined(DIRLIGHTMAP_COMBINED)
                dominantDir = _SpecularDirection.xyz;
                specColor = light.indirectDiffuse;
            #endif
            #ifndef LIGHTMAP_ON
                specColor = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
                dominantDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
            #endif
        }
    #endif

    half3 halfDir = Unity_SafeNormalize(normalize(dominantDir) + viewDir );
    half nh = saturate(dot(worldNormal, halfDir));
    half spec = D_GGX(nh, roughness);
    return spec * specColor;
}


//ACES
#ifdef ENABLE_TONEMAPPING
uniform  float _temperature;
uniform float _tint;

#define _ColorBalance ComputeColorBalance(_temperature,_tint)


uniform half4 _ColorFilter;


uniform float3 _ChannelMixerRed;
uniform float3 _ChannelMixerGreen;
uniform float3 _ChannelMixerBlue;

//#define _ChannelMixerRed float3(1,0,0) // Remap to [-2;2]
//#define _ChannelMixerGreen float3(0,1,0) // Remap to [-2;2]
//#define _ChannelMixerBlue float3(0,0,1) // Remap to [-2;2]

uniform  float _lift;
uniform  float _gain;
uniform float _invGamma;

#define _Lift float4(_lift* 0.2f,_lift* 0.2f,_lift* 0.2f,0.0f)
#define _Gain float4(_gain* 0.8f,_gain* 0.8f,_gain* 0.8f,0.0f)
#define _InvGamma float4(_invGamma* 0.8f,_invGamma* 0.8f,_invGamma* 0.8f,0.0f)

uniform float _hue;
uniform float _sat;
uniform float _con;

//#define _hue 0  / 360.0f                        // Remap to [-0.5;0.5]
//#define _sat 0  / 100.0f + 1.0f                   // Remap to [0;2]
//#define _con 0  / 100.0f + 1.0f                   // Remap to [0;2]
#define _HueSatCon float4(_hue/ 360.0f ,_sat/ 100.0f + 1.0f,_con/ 100.0f + 1.0f,0.0f)


Texture2D _Curves;
SamplerState sampler_Curves;




#define LUT_SPACE_ENCODE(x) LinearToLogC(x)
#define LUT_SPACE_DECODE(x) LogCToLinear(x)

#define ACEScc_MAX      1.4679964
#define ACEScc_MIDGRAY  0.4135884


#define HALF_MAX        65504.0 // (2 - 2^-10) * 2^15
#define HALF_MAX_MINUS1 65472.0 // (2 - 2^-9) * 2^15
#define EPSILON         1.0e-4
#define PI              3.14159265359
#define TWO_PI          6.28318530718
#define FOUR_PI         12.56637061436
#define INV_PI          0.31830988618
#define INV_TWO_PI      0.15915494309
#define INV_FOUR_PI     0.07957747155
#define HALF_PI         1.57079632679
#define INV_HALF_PI     0.636619772367

#define FLT_EPSILON     1.192092896e-07 // Smallest positive number, such that 1.0 + FLT_EPSILON != 1.0
#define FLT_MIN         1.175494351e-38 // Minimum representable positive floating-point number
#define FLT_MAX         3.402823466e+38 // Maximum representable floating-point number


#ifndef USE_PRECISE_LOGC
    // Set to 1 to use more precise but more expensive log/linear conversions. I haven't found a proper
    // use case for the high precision version yet so I'm leaving this to 0.
    #define USE_PRECISE_LOGC 0
#endif

#ifndef TONEMAPPING_USE_FULL_ACES
    // Set to 1 to use the full reference ACES tonemapper. This should only be used for research
    // purposes as it's quite heavy and generally overkill.
    #define TONEMAPPING_USE_FULL_ACES 0
#endif

#ifndef DEFAULT_MAX_PQ
    // PQ ST.2048 max value
    // 1.0 = 100nits, 100.0 = 10knits
    #define DEFAULT_MAX_PQ 100.0
#endif

#ifndef USE_VERY_FAST_SRGB
    #if defined(SHADER_API_MOBILE)
        #define USE_VERY_FAST_SRGB 1
    #else
        #define USE_VERY_FAST_SRGB 0
    #endif
#endif

#ifndef USE_FAST_SRGB
    #if defined(SHADER_API_CONSOLE)
        #define USE_FAST_SRGB 1
    #else
        #define USE_FAST_SRGB 0
    #endif
#endif

//
// Alexa LogC converters (El 1000)
// See http://www.vocas.nl/webfm_send/964
// Max range is ~58.85666
//
struct ParamsLogC
{
    float cut;
    float a, b, c, d, e, f;
};

static const ParamsLogC LogC =
{
    0.011361, // cut
    5.555556, // a
    0.047996, // b
    0.244161, // c
    0.386036, // d
    5.301883, // e
    0.092819  // f
};

float LinearToLogC_Precise(half x)
{
    float o;
    if (x > LogC.cut)
        o = LogC.c * log10(LogC.a * x + LogC.b) + LogC.d;
    else
        o = LogC.e * x + LogC.f;
    return o;
}

float3 LinearToLogC(float3 x)
{
#if USE_PRECISE_LOGC
    return float3(
        LinearToLogC_Precise(x.x),
        LinearToLogC_Precise(x.y),
        LinearToLogC_Precise(x.z)
    );
#else
    return LogC.c * log10(LogC.a * x + LogC.b) + LogC.d;
#endif
}

float LogCToLinear_Precise(float x)
{
    float o;
    if (x > LogC.e * LogC.cut + LogC.f)
        o = (pow(10.0, (x - LogC.d) / LogC.c) - LogC.b) / LogC.a;
    else
        o = (x - LogC.f) / LogC.e;
    return o;
}

float3 LogCToLinear(float3 x)
{
#if USE_PRECISE_LOGC
    return float3(
        LogCToLinear_Precise(x.x),
        LogCToLinear_Precise(x.y),
        LogCToLinear_Precise(x.z)
    );
#else
    return (pow(10.0, (x - LogC.d) / LogC.c) - LogC.b) / LogC.a;
#endif
}

static const half3x3 D60_2_D65_CAT = {
    0.98722400, -0.00611327, 0.0159533,
   -0.00759836,  1.00186000, 0.0053302,
    0.00307257, -0.00509595, 1.0816800
};

static const half3x3 sRGB_2_AP0 = {
    0.4397010, 0.3829780, 0.1773350,
    0.0897923, 0.8134230, 0.0967616,
    0.0175440, 0.1115440, 0.8707040
};

static const half3x3 AP0_2_AP1_MAT = {
    1.4514393161, -0.2365107469, -0.2149285693,
   -0.0765537734,  1.1762296998, -0.0996759264,
    0.0083161484, -0.0060324498,  0.9977163014
};

static const half3x3 AP1_2_AP0_MAT = {
    0.6954522414, 0.1406786965, 0.1638690622,
    0.0447945634, 0.8596711185, 0.0955343182,
   -0.0055258826, 0.0040252103, 1.0015006723
};

static const half3x3 AP1_2_XYZ_MAT = {
    0.6624541811, 0.1340042065, 0.1561876870,
    0.2722287168, 0.6740817658, 0.0536895174,
   -0.0055746495, 0.0040607335, 1.0103391003
};

static const half3x3 XYZ_2_AP1_MAT = {
    1.6410233797, -0.3248032942, -0.2364246952,
   -0.6636628587,  1.6153315917,  0.0167563477,
    0.0117218943, -0.0082844420,  0.9883948585
};

static const half3x3 XYZ_2_REC709_MAT = {
    3.2409699419, -1.5373831776, -0.4986107603,
   -0.9692436363,  1.8759675015,  0.0415550574,
    0.0556300797, -0.2039769589,  1.0569715142
};

static const float3x3 LIN_2_LMS_MAT = {
    3.90405e-1, 5.49941e-1, 8.92632e-3,
    7.08416e-2, 9.63172e-1, 1.35775e-3,
    2.31082e-2, 1.28021e-1, 9.36245e-1
};

static const float3x3 LMS_2_LIN_MAT = {
    2.85847e+0, -1.62879e+0, -2.48910e-2,
    -2.10182e-1,  1.15820e+0,  3.24281e-4,
    -4.18120e-2, -1.18169e-1,  1.06867e+0
};


half3 unity_to_ACES(half3 x)
{
    x = mul(sRGB_2_AP0, x);
    return x;
}

half ACES_to_ACEScc(half x)
{
    if (x <= 0.0)
        return -0.35828683; // = (log2(pow(2.0, -15.0) * 0.5) + 9.72) / 17.52
    else if (x < pow(2.0, -15.0))
        return (log2(pow(2.0, -16.0) + x * 0.5) + 9.72) / 17.52;
    else // (x >= pow(2.0, -15.0))
        return (log2(x) + 9.72) / 17.52;
}

half3 ACES_to_ACEScc(half3 x)
{
    x = clamp(x, 0.0, HALF_MAX);

    // x is clamped to [0, HALF_MAX], skip the <= 0 check
    return (x < 0.00003051757) ? (log2(0.00001525878 + x * 0.5) + 9.72) / 17.52 : (log2(x) + 9.72) / 17.52;

    /*
    return half3(
    ACES_to_ACEScc(x.r),
    ACES_to_ACEScc(x.g),
    ACES_to_ACEScc(x.b)
    );
    */
}

float3 Contrast(float3 c, float midpoint, float contrast)
{
    return (c - midpoint) * contrast + midpoint;
}

float3 LogGrade(float3 colorLog)
{
    // Contrast feels a lot more natural when done in log rather than doing it in linear
    colorLog = Contrast(colorLog, ACEScc_MIDGRAY, _HueSatCon.z);

    return colorLog;
}

half ACEScc_to_ACES(half x)
{
    // TODO: Optimize me
    if (x < -0.3013698630) // (9.72 - 15) / 17.52
        return (pow(2.0, x * 17.52 - 9.72) - pow(2.0, -16.0)) * 2.0;
    else if (x < (log2(HALF_MAX) + 9.72) / 17.52)
        return pow(2.0, x * 17.52 - 9.72);
    else // (x >= (log2(HALF_MAX) + 9.72) / 17.52)
        return HALF_MAX;
}

half3 ACEScc_to_ACES(half3 x)
{
    return half3(
        ACEScc_to_ACES(x.r),
        ACEScc_to_ACES(x.g),
        ACEScc_to_ACES(x.b)
    );
}

half3 ACES_to_ACEScg(half3 x)
{
    return mul(AP0_2_AP1_MAT, x);
}

float Min3(float a, float b, float c)
{
    return min(min(a, b), c);
}

float2 Min3(float2 a, float2 b, float2 c)
{
    return min(min(a, b), c);
}

float3 Min3(float3 a, float3 b, float3 c)
{
    return min(min(a, b), c);
}

float4 Min3(float4 a, float4 b, float4 c)
{
    return min(min(a, b), c);
}

float Max3(float a, float b, float c)
{
    return max(max(a, b), c);
}

float2 Max3(float2 a, float2 b, float2 c)
{
    return max(max(a, b), c);
}

float3 Max3(float3 a, float3 b, float3 c)
{
    return max(max(a, b), c);
}

float4 Max3(float4 a, float4 b, float4 c)
{
    return max(max(a, b), c);
}

half rgb_2_saturation(half3 rgb)
{
    const half TINY = 1e-4;
    half mi = Min3(rgb.r, rgb.g, rgb.b);
    half ma = Max3(rgb.r, rgb.g, rgb.b);
    return (max(ma, TINY) - max(mi, TINY)) / max(ma, 1e-2);
}

half rgb_2_yc(half3 rgb)
{
    const half ycRadiusWeight = 1.75;

    // Converts RGB to a luminance proxy, here called YC
    // YC is ~ Y + K * Chroma
    // Constant YC is a cone-shaped surface in RGB space, with the tip on the
    // neutral axis, towards white.
    // YC is normalized: RGB 1 1 1 maps to YC = 1
    //
    // ycRadiusWeight defaults to 1.75, although can be overridden in function
    // call to rgb_2_yc
    // ycRadiusWeight = 1 -> YC for pure cyan, magenta, yellow == YC for neutral
    // of same value
    // ycRadiusWeight = 2 -> YC for pure red, green, blue  == YC for  neutral of
    // same value.

    half r = rgb.x;
    half g = rgb.y;
    half b = rgb.z;
    half chroma = sqrt(b * (b - g) + g * (g - r) + r * (r - b));
    return (b + g + r + ycRadiusWeight * chroma) / 3.0;
}

float FastSign(float x)
{
    return saturate(x * FLT_MAX + 0.5) * 2.0 - 1.0;
}

float2 FastSign(float2 x)
{
    return saturate(x * FLT_MAX + 0.5) * 2.0 - 1.0;
}

float3 FastSign(float3 x)
{
    return saturate(x * FLT_MAX + 0.5) * 2.0 - 1.0;
}

float4 FastSign(float4 x)
{
    return saturate(x * FLT_MAX + 0.5) * 2.0 - 1.0;
}

half sigmoid_shaper(half x)
{
    // Sigmoid function in the range 0 to 1 spanning -2 to +2.

    half t = max(1.0 - abs(x / 2.0), 0.0);
    half y = 1.0 + FastSign(x) * (1.0 - t * t);

    return y / 2.0;
}

half glow_fwd(half ycIn, half glowGainIn, half glowMid)
{
    half glowGainOut;

    if (ycIn <= 2.0 / 3.0 * glowMid)
        glowGainOut = glowGainIn;
    else if (ycIn >= 2.0 * glowMid)
        glowGainOut = 0.0;
    else
        glowGainOut = glowGainIn * (glowMid / ycIn - 1.0 / 2.0);

    return glowGainOut;
}

half rgb_2_hue(half3 rgb)
{
    // Returns a geometric hue angle in degrees (0-360) based on RGB values.
    // For neutral colors, hue is undefined and the function will return a quiet NaN value.
    half hue;
    if (rgb.x == rgb.y && rgb.y == rgb.z)
        hue = 0.0; // RGB triplets where RGB are equal have an undefined hue
    else
        hue = (180.0 / PI) * atan2(sqrt(3.0) * (rgb.y - rgb.z), 2.0 * rgb.x - rgb.y - rgb.z);

    if (hue < 0.0) hue = hue + 360.0;

    return hue;
}

half center_hue(half hue, half centerH)
{
    half hueCentered = hue - centerH;
    if (hueCentered < -180.0) hueCentered = hueCentered + 360.0;
    else if (hueCentered > 180.0) hueCentered = hueCentered - 360.0;
    return hueCentered;
}

static const half RRT_GLOW_GAIN = 0.05;
static const half RRT_GLOW_MID = 0.08;

static const half RRT_RED_SCALE = 0.82;
static const half RRT_RED_PIVOT = 0.03;
static const half RRT_RED_HUE = 0.0;
static const half RRT_RED_WIDTH = 135.0;

static const half RRT_SAT_FACTOR = 0.96;

static const half DIM_SURROUND_GAMMA = 0.9811;

static const half3 AP1_RGB2Y = half3(0.272229, 0.674082, 0.0536895);

static const half CINEMA_WHITE = 48.0;
static const half CINEMA_BLACK = CINEMA_WHITE / 2400.0;
static const half ODT_SAT_FACTOR = 0.93;

half3 XYZ_2_xyY(half3 XYZ)
{
    half divisor = max(dot(XYZ, (1.0).xxx), 1e-4);
    return half3(XYZ.xy / divisor, XYZ.y);
}

half3 xyY_2_XYZ(half3 xyY)
{
    half m = xyY.z / max(xyY.y, 1e-4);
    half3 XYZ = half3(xyY.xz, (1.0 - xyY.x - xyY.y));
    XYZ.xz *= m;
    return XYZ;
}

half3 darkSurround_to_dimSurround(half3 linearCV)
{
    half3 XYZ = mul(AP1_2_XYZ_MAT, linearCV);

    half3 xyY = XYZ_2_xyY(XYZ);
    xyY.z = clamp(xyY.z, 0.0, HALF_MAX);
    xyY.z = pow(xyY.z, DIM_SURROUND_GAMMA);
    XYZ = xyY_2_XYZ(xyY);

    return mul(XYZ_2_AP1_MAT, XYZ);
}

float3 RgbToHsv(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = EPSILON;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HsvToRgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float RotateHue(float value, float low, float hi)
{
    return (value < low)
            ? value + hi
            : (value > hi)
                ? value - hi
                : value;
}

float3 ChannelMixer(float3 c, float3 red, float3 green, float3 blue)
{
    return float3(
        dot(c, red),
        dot(c, green),
        dot(c, blue)
    );
}

float3 WhiteBalance(float3 c, float3 balance)
{
    float3 lms = mul(LIN_2_LMS_MAT, c);
    lms *= balance;
    return mul(LMS_2_LIN_MAT, lms);
}

float3 LiftGammaGainHDR(float3 c, float3 lift, float3 invgamma, float3 gain)
{
    c = c * gain + lift;

    // ACEScg will output negative values, as clamping to 0 will lose precious information we'll
    // mirror the gamma function instead
    return FastSign(c) * pow(abs(c), invgamma);
}

float3 Saturation(float3 c, float sat)
{
    float luma = Luminance(c);
    return luma.xxx + sat.xxx * (c - luma.xxx);
}

 static const float StandardIlluminantY(float x)
{
    return 2.87f * x - 3.0f * x * x - 0.27509507f;
}

static const float3 CIExyToLMS(float x, float y)
{
    float Y = 1.0f;
    float X = Y * x / y;
    float Z = Y * (1.0f - x - y) / y;

    float L = 0.7328f * X + 0.4296f * Y - 0.1624f * Z;
    float M = -0.7036f * X + 1.6975f * Y + 0.0061f * Z;
    float S = 0.0030f * X + 0.0136f * Y + 0.9834f * Z;

    return float3(L, M, S);
}

 float3 ComputeColorBalance(float temperature, float tint)
{
    // Range ~[-1.67;1.67] works best
    float t1 = temperature / 60.0f;
    float t2 = tint / 60.0f;

    // Get the CIE xy chromaticity of the reference white point.
    // Note: 0.31271 = x value on the D65 white point
    float x = 0.31271f - t1 * (t1 < 0.0f ? 0.1f : 0.05f);
    float y = StandardIlluminantY(x) + t2 * 0.05f;

    // Calculate the coefficients in the LMS space.
    float3 w1 = float3(0.949237f, 1.03542f, 1.08728f); // D65 white point
    float3 w2 = CIExyToLMS(x, y);
    return  float3(w1.x / w2.x, w1.y / w2.y, w1.z / w2.z);
}





float3 LinearGrade(float3 colorLinear)
{
    colorLinear = WhiteBalance(colorLinear, _ColorBalance.rgb);
    colorLinear *= _ColorFilter.rgb;
    colorLinear = ChannelMixer(colorLinear, _ChannelMixerRed.rgb, _ChannelMixerGreen.rgb, _ChannelMixerBlue.rgb);
    colorLinear = LiftGammaGainHDR(colorLinear, _Lift.rgb, _InvGamma.rgb, _Gain.rgb);

    // Do NOT feed negative values to RgbToHsv or they'll wrap around
    colorLinear = max(0.0, colorLinear);

    float3 hsv = RgbToHsv(colorLinear);

    // Hue Vs Sat
    float satMult = 1;
    
    satMult = saturate(_Curves.SampleLevel(sampler_Curves, float2(hsv.x, 0.25), 0).y) * 2.0;

    // Sat Vs Sat
    satMult *= saturate(_Curves.SampleLevel(sampler_Curves, float2(hsv.y, 0.25), 0).z) * 2.0;

    // Lum Vs Sat
    satMult *= saturate(_Curves.SampleLevel(sampler_Curves, float2(Luminance(colorLinear), 0.25), 0).w) * 2.0;
    
    // Hue Vs Hue
    float hue = hsv.x + _HueSatCon.x;
    float offset = saturate(_Curves.SampleLevel(sampler_Curves, float2(hue, 0.25), 0).x) - 0.5;
    hue += offset;
    hsv.x = RotateHue(hue, 0.0, 1.0);

    colorLinear = HsvToRgb(hsv);
    colorLinear = Saturation(colorLinear, _HueSatCon.y * satMult);

    return colorLinear;
}


float3 AcesTonemap(float3 aces)
{
#if TONEMAPPING_USE_FULL_ACES

    float3 oces = RRT(aces);
    float3 odt = ODT_RGBmonitor_100nits_dim(oces);
    return odt;

#else

    // --- Glow module --- //
    float saturation = rgb_2_saturation(aces);
    float ycIn = rgb_2_yc(aces);
    float s = sigmoid_shaper((saturation - 0.4) / 0.2);
    float addedGlow = 1.0 + glow_fwd(ycIn, RRT_GLOW_GAIN * s, RRT_GLOW_MID);
    aces *= addedGlow;

    // --- Red modifier --- //
    float hue = rgb_2_hue(aces);
    float centeredHue = center_hue(hue, RRT_RED_HUE);
    float hueWeight;
    {
        //hueWeight = cubic_basis_shaper(centeredHue, RRT_RED_WIDTH);
        hueWeight = smoothstep(0.0, 1.0, 1.0 - abs(2.0 * centeredHue / RRT_RED_WIDTH));
        hueWeight *= hueWeight;
    }

    aces.r += hueWeight * saturation * (RRT_RED_PIVOT - aces.r) * (1.0 - RRT_RED_SCALE);

    // --- ACES to RGB rendering space --- //
    float3 acescg = max(0.0, ACES_to_ACEScg(aces));

    // --- Global desaturation --- //
    //acescg = mul(RRT_SAT_MAT, acescg);
    acescg = lerp(dot(acescg, AP1_RGB2Y).xxx, acescg, RRT_SAT_FACTOR.xxx);

    // Luminance fitting of *RRT.a1.0.3 + ODT.Academy.RGBmonitor_100nits_dim.a1.0.3*.
    // https://github.com/colour-science/colour-unity/blob/master/Assets/Colour/Notebooks/CIECAM02_Unity.ipynb
    // RMSE: 0.0012846272106
    const float a = 278.5085;
    const float b = 10.7772;
    const float c = 293.6045;
    const float d = 88.7122;
    const float e = 80.6889;
    float3 x = acescg;
    float3 rgbPost = (x * (a * x + b)) / (x * (c * x + d) + e);

    // Scale luminance to linear code value
    // float3 linearCV = Y_2_linCV(rgbPost, CINEMA_WHITE, CINEMA_BLACK);

    // Apply gamma adjustment to compensate for dim surround
    float3 linearCV = darkSurround_to_dimSurround(rgbPost);

    // Apply desaturation to compensate for luminance difference
    //linearCV = mul(ODT_SAT_MAT, color);
    linearCV = lerp(dot(linearCV, AP1_RGB2Y).xxx, linearCV, ODT_SAT_FACTOR.xxx);

    // Convert to display primary encoding
    // Rendering space RGB to XYZ
    float3 XYZ = mul(AP1_2_XYZ_MAT, linearCV);

    // Apply CAT from ACES white point to assumed observer adapted white point
    XYZ = mul(D60_2_D65_CAT, XYZ);

    // CIE XYZ to display primaries
    linearCV = mul(XYZ_2_REC709_MAT, XYZ);

    return linearCV;

#endif
}

half3 ACEScg_to_ACES(half3 x)
{
    return mul(AP1_2_AP0_MAT, x);
}

float3 ColorGrade(float3 colorLutSpace)
{
    float3 colorLinear = LUT_SPACE_DECODE(colorLutSpace);
    float3 aces = unity_to_ACES(colorLinear);

    // ACEScc (log) space
    float3 acescc = ACES_to_ACEScc(aces);
    acescc = LogGrade(acescc);
    aces = ACEScc_to_ACES(acescc);

    // ACEScg (linear) space
    float3 acescg = ACES_to_ACEScg(aces);
    acescg = LinearGrade(acescg);

    // Tonemap ODT(RRT(aces))
    aces = ACEScg_to_ACES(acescg);
    colorLinear = AcesTonemap(aces);

    return colorLinear;
}
#endif