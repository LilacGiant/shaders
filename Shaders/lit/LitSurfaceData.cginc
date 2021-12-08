float2 GetUVs(float4 st, uint type)
{
    float2 uv = 0;

    switch(type)
    {
        case 0:
            uv = float2(input.coord0.xy * _MainTex_ST.xy + _MainTex_ST.zw + parallaxOffset);
            break;
        case 1:
            uv = float2(input.coord0.zw * st.xy + st.zw + parallaxOffset);
            break;
        case 2:
            uv = float2(input.coord1.xy * st.xy + st.zw + parallaxOffset);
            break;
        case 3:
            uv = float2(input.coord0.xy * st.xy + st.zw + parallaxOffset);
            break;
    }

    return uv;
}

float4 SampleTexture(Texture2D tex, float4 st, sampler s, int type)
{
    return tex.Sample(s, GetUVs(st, type));
}

float4 SampleTexture(Texture2D tex, float4 st, int type)
{
    return SampleTexture(tex, st, defaultSampler, type);
}

float4 SampleTextureArray(Texture2DArray tex, SamplerState s, float4 st, int type)
{
    return tex.Sample(s, float3(GetUVs(st, type), textureIndex));
}

void InitializeLitSurfaceData(inout SurfaceData surf, v2f i)
{

    #if defined(TEXTUREARRAY)
        defaultSampler = sampler_MainTexArray;
        #ifdef TEXTUREARRAYINSTANCED
            textureIndex = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureIndex);
        #else
            textureIndex = i.coord1.z;
        #endif
        float4 mainTexture = SampleTextureArray(_MainTexArray, defaultSampler, _MainTex_ST, _MainTex_UV);
    #else
        defaultSampler = sampler_MainTex;
        float4 mainTexture = SampleTexture(_MainTex, _MainTex_ST, defaultSampler, _MainTex_UV);
    #endif

    mainTexture *= _Color;
    
    surf.albedo = mainTexture.rgb;
    surf.alpha = mainTexture.a;


    float4 maskMap = 1;
    float metallicMap = 1;
    float smoothnessMap = 1;
    float occlusionMap = 1;
    bool hasOcclusion = 0;

    #ifdef _WORKFLOW_UNPACKED

        if(_MetallicMap_TexelSize.x != 1) metallicMap = SampleTexture(_MetallicMap, _MetallicMap_ST, _MetallicMap_UV);
        if(_SmoothnessMap_TexelSize.x != 1) 
        {
            smoothnessMap = SampleTexture(_SmoothnessMap, _SmoothnessMap_ST, _SmoothnessMap_UV);
            smoothnessMap = _GlossinessInvert ? 1-smoothnessMap : smoothnessMap;
        }
        if(_OcclusionMap_TexelSize.x != 1)
        {
            occlusionMap = SampleTexture(_OcclusionMap, _OcclusionMap_ST, _OcclusionMap_UV);
            hasOcclusion = 1;
        }

    #else

        #if defined(TEXTUREARRAY)
            if(_MetallicGlossMapArray_TexelSize.x != 1)
            {
                maskMap = SampleTextureArray(_MetallicGlossMapArray, defaultSampler, _MetallicGlossMap_ST, _MetallicGlossMap_UV);
                hasOcclusion = 1;
            }
        #else
            if(_MetallicGlossMap_TexelSize.x != 1)
            {
                maskMap = SampleTexture(_MetallicGlossMap, _MetallicGlossMap_ST, _MetallicGlossMap_UV);
                hasOcclusion = 1;
            }
        #endif
        
        metallicMap = maskMap.r;
        smoothnessMap = maskMap.a;
        occlusionMap = maskMap.g;
    #endif

    surf.perceptualRoughness = 1 - (RemapMinMax(smoothnessMap, _GlossinessMin, _Glossiness));
    // surf.metallic = metallicMap * _Metallic * _Metallic;
    surf.metallic = RemapMinMax(metallicMap, _MetallicMin, _Metallic * _Metallic);
    // surf.occlusion = lerp(1, occlusionMap, _Occlusion);
    surf.occlusion = hasOcclusion ? RemapMinMax(occlusionMap, _OcclusionMin, _Occlusion) : 1;

    float4 normalMap = float4(0.5, 0.5, 1, 1);
    #if defined(TEXTUREARRAY)
        if(_BumpMapArray_TexelSize.x != 1) normalMap = SampleTextureArray(_BumpMapArray, sampler_BumpMapArray, _BumpMap_ST, _BumpMap_UV);
    #else
        if(_BumpMap_TexelSize.x != 1) normalMap = SampleTexture(_BumpMap, _BumpMap_ST, sampler_BumpMap, _BumpMap_UV);
    #endif
    if(!_HemiOctahedron) surf.tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);
    else surf.tangentNormal = UnpackScaleNormalHemiOctahedron(normalMap, _BumpScale);

    float4 detailNormalMap = float4(0.5, 0.5, 1, 1);
    #if defined(PROP_DETAILMAP) || defined(PROP_DETAILALBEDOMAP) || defined(PROP_DETAILNORMALMAP) || defined(PROP_DETAILMASKMAP)

        float detailMask = lerp(1, maskMap.b, _DetailMaskScale);
        float4 detailMap = 0.5;
        float3 detailAlbedo = 0;
        float detailSmoothness = 0;
        
        if(_DetailPacked)
        {
            #if defined(PROP_DETAILMAP)
                detailMap = SampleTexture(_DetailMap, _DetailMap_ST, _DetailMap_UV);
                detailAlbedo = detailMap.r * 2.0 - 1.0;
                detailSmoothness = (detailMap.b * 2.0 - 1.0);
                detailNormalMap = float4(detailMap.a, detailMap.g, 1, 1);
            #endif
        }
        else
        {
            #if defined(PROP_DETAILALBEDOMAP)
                detailAlbedo = SampleTexture(_DetailAlbedoMap, _DetailMap_ST, _DetailMap_UV).rgb * 2.0 - 1.0;
            #endif

            #if defined(PROP_DETAILNORMALMAP)
                detailNormalMap = SampleTexture(_DetailNormalMap, _DetailMap_ST, _DetailMap_UV);
            #endif

            #if defined(PROP_DETAILMASKMAP)
                detailSmoothness = SampleTexture(_DetailMaskMap, _DetailMap_ST, _DetailMap_UV).r * 2.0 - 1.0;
            #endif
        }

        
        #if defined(PROP_DETAILMAP) || defined(PROP_DETAILALBEDOMAP)
            // Goal: we want the detail albedo map to be able to darken down to black and brighten up to white the surface albedo.
            // The scale control the speed of the gradient. We simply remap detailAlbedo from [0..1] to [-1..1] then perform a lerp to black or white
            // with a factor based on speed.
            // For base color we interpolate in sRGB space (approximate here as square) as it get a nicer perceptual gradient

            float3 albedoDetailSpeed = saturate(abs(detailAlbedo) * _DetailAlbedoScale);
            float3 baseColorOverlay = lerp(sqrt(surf.albedo.rgb), (detailAlbedo < 0.0) ? float3(0.0, 0.0, 0.0) : float3(1.0, 1.0, 1.0), albedoDetailSpeed * albedoDetailSpeed);
            baseColorOverlay *= baseColorOverlay;							   
            // Lerp with details mask
            surf.albedo.rgb = lerp(surf.albedo.rgb, saturate(baseColorOverlay), detailMask);
        #endif

        #if defined(PROP_DETAILMAP) || defined(PROP_DETAILMASKMAP)
            float perceptualSmoothness = (1 - surf.perceptualRoughness);
            // See comment for baseColorOverlay
            float smoothnessDetailSpeed = saturate(abs(detailSmoothness) * _DetailSmoothnessScale);
            float smoothnessOverlay = lerp(perceptualSmoothness, (detailSmoothness < 0.0) ? 0.0 : 1.0, smoothnessDetailSpeed);
            // Lerp with details mask
            perceptualSmoothness = lerp(perceptualSmoothness, saturate(smoothnessOverlay), detailMask);

            surf.perceptualRoughness = (1 - perceptualSmoothness);
        #endif

        #if defined(PROP_DETAILMAP) || defined(PROP_DETAILNORMALMAP)
            detailNormalMap.g = 1-detailNormalMap.g;
            float3 detailNormal = UnpackScaleNormal(detailNormalMap, _DetailNormalScale);
            surf.tangentNormal = BlendNormals(surf.tangentNormal, detailNormal);
        #endif
        
    #endif
    
    surf.albedo.rgb = lerp(dot(surf.albedo.rgb, grayscaleVec), surf.albedo.rgb, _Saturation + 1);

    #if defined(EMISSION)
        float3 emissionMap = 1;
        if(_EmissionMap_TexelSize.x != 1) emissionMap = SampleTexture(_EmissionMap, _EmissionMap_ST, _EmissionMap_UV).rgb;

        if(_EmissionMultBase) emissionMap *= surf.albedo.rgb;
        #ifdef ENABLE_AUDIOLINK
            ApplyAudioLinkEmission(emissionMap);
        #endif

        surf.emission = emissionMap * pow(_EmissionColor, 2.2);
    #endif

    surf.reflectance = _Reflectance;

    #ifdef ANISOTROPY
        #if defined(PROP_ANISOTROPYMAP)
            surf.anisotropicDirection = _AnisotropyMap.Sample(defaultSampler, (i.coord0.xy * _AnisotropyMap_ST.xy + _AnisotropyMap_ST.zw)).rg;
        #endif
        surf.anisotropy = _Anisotropy;
    #endif

}