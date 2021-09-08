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
            case 1:
                clip(alpha - 0.01);
                break;
            case 2:
                alpha = (alpha - _Cutoff) / max(fwidth(alpha), 0.0001) + 0.5;
                clip(alpha - 0.01);
                break;
        }

    }

    return alpha;
}

void initNormalMap(half4 normalMap, inout half3 bitangent, inout half3 tangent, inout half3 normal, half4 detailNormalMap)
{
    normalMap.g = _NormalMapOrientation ? normalMap.g : 1-normalMap.g;

    half3 tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);

    #if defined(PROP_DETAILMAP) && !defined(SHADER_API_MOBILE)
        detailNormalMap.g = 1-detailNormalMap.g;
        half3 detailNormal = UnpackScaleNormal(detailNormalMap, _DetailNormalScale);
        tangentNormal = BlendNormals(tangentNormal, detailNormal);
    #endif

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
    if(_Mode == 1) clip(alpha - _Cutoff);
    return float4(UnityMetaFragment(metaInput).rgb, alpha);
}
#endif

void applyEmission(half2 parallaxOffset)
{
    half4 emissionMap = 1;
    #if defined(PROP_EMISSIONMAP)
        emissionMap = _EmissionMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_EmissionMapUV], _EmissionMap_ST, _MainTex_ST));
    #endif

    #if defined(ENABLE_AUDIOLINK) && !defined (SHADER_API_MOBILE)
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


half3 getDirectSpecular(float3 worldNormal, half3 tangent, half3 bitangent, half3 f0, half NoV)
{
    half NoH = saturate(dot(worldNormal, light.halfVector));

    half roughness = max(surface.perceptualRoughness * surface.perceptualRoughness, 0.002);

    half D = GGXTerm (NoH, roughness);

    float anisotropy = _Anisotropy;
    #if !defined(SHADER_API_MOBILE)
        if(anisotropy != 0) {
            anisotropy *= saturate(5.0 * surface.perceptualRoughness);
            half at = max(roughness * (1.0 + anisotropy), 0.001);
            half ab = max(roughness * (1.0 - anisotropy), 0.001);
            D = D_GGX_Anisotropic(NoH, light.halfVector, tangent, bitangent, at, ab);
        }
    #endif

    half V = V_SmithGGXCorrelated ( NoV,light.NoL, roughness);
    half3 F = F_Schlick(light.LoH, f0);

    half3 specularTerm = max(0, (D * V) * F);

    return specularTerm * UNITY_PI * light.finalLight;
}

half3 getIndirectSpecular(float3 reflDir, float3 worldPos, float3 reflWorldNormal, half3 fresnel, half3 f0)
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
    
    #if !defined(SHADER_API_MOBILE)
    
        #if defined(UNITY_SPECCUBE_BLENDING) && !defined(ENABLE_REFRACTION)
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
    #endif

    return indirectSpecular * lerp(fresnel, f0, surface.perceptualRoughness);
}

#if !defined(UNITY_PASS_SHADOWCASTER)
void initLighting(v2f i, float3 worldNormal, float3 viewDir, half NoV)
{
    light.indirectDominantColor = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    light.direction = getLightDir(!_GetDominantLight, i.worldPos);
    light.color = getLightCol(!_GetDominantLight, _LightColor0.rgb, light.indirectDominantColor) * 0.95;
    light.halfVector = Unity_SafeNormalize(light.direction + viewDir);
    light.NoL = saturate(dot(worldNormal, light.direction));
    light.LoH = saturate(dot(light.direction, light.halfVector));
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
    light.attenuation = attenuation;
    light.finalLight = (light.NoL * light.attenuation * light.color);
    #ifndef SHADER_API_MOBILE
        light.finalLight *= Fd_Burley(surface.perceptualRoughness, NoV, light.NoL, light.LoH);
    #endif
}
#endif

#if defined(PROP_DETAILMAP) && !defined(SHADER_API_MOBILE)
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
    half desaturated = dot(surface.albedo.rgb, grayscaleVec); // saturation has to be applied after detail
    surface.albedo.rgb = lerp(desaturated, surface.albedo.rgb, (_Saturation+1));
}

void initSurfaceData(out half metallicMap, out half smoothnessMap, out half occlusionMap, out half4 maskMap, half2 parallaxOffset)
{
    metallicMap = 1;
    smoothnessMap = 1;
    occlusionMap = 1;
    maskMap = 1;
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

void getMainTex(out half4 mainTex, half2 parallaxOffset, half4 vertexColor)
{
    mainTex = MAIN_TEX(_MainTex, sampler_MainTex, uvs[_MainTexUV], _MainTex_ST);

    

    surface.albedo = mainTex * _Color;

    #ifdef PROP_ENABLEVERTEXCOLOR
        surface.albedo.rgb *= _EnableVertexColor ? GammaToLinearSpace(vertexColor) : 1;
    #endif
}

void getIndirectDiffuse(float3 worldNormal, float2 parallaxOffset)
{
    #if defined(LIGHTMAP_ON)

        half3 lightMap = getLightmap(uvs[1], worldNormal, parallaxOffset);
        #if defined(DYNAMICLIGHTMAP_ON) && !defined(SHADER_API_MOBILE)
            half3 realtimeLightMap = getRealtimeLightmap(uvs[2], worldNormal, parallaxOffset);
            lightMap += realtimeLightMap; 
        #endif
        light.indirectDiffuse = lightMap;

    #else

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