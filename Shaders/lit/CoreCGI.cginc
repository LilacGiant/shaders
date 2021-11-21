float4 frag (v2f i, uint facing : SV_IsFrontFace) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i)
    input = i;

    #if defined(LOD_FADE_CROSSFADE)
		UnityApplyDitherCrossFade(i.pos);
	#endif

    #if defined(PARALLAX)
        parallaxOffset = ParallaxOffset(i.parallaxViewDir);
    #endif


    SurfaceData surf;
    InitializeDefaultSurfaceData(surf);
    InitializeLitSurfaceData(surf, i);


#if defined(UNITY_PASS_SHADOWCASTER)

    #if defined(_MODE_CUTOUT)
        if(surf.alpha < _Cutoff) discard;
    #endif

    #if defined (_MODE_FADE) || defined (_MODE_TRANSPARENT)
        if(surf.alpha < 0.5) discard;
    #endif

    SHADOW_CASTER_FRAGMENT(i);
#else

    #if defined (_MODE_CUTOUT)
        if(_AlphaToMask) surf.alpha = (surf.alpha - _Cutoff) / max(fwidth(surf.alpha), 0.0001) + 0.5;
        else if(surf.alpha < _Cutoff) discard;
    #endif

    float3 worldNormal = i.worldNormal;
    float3 bitangent = i.bitangent;
    float3 tangent = i.tangent;

    if(!facing)
    {
        worldNormal *= -1;
        bitangent *= -1;
        tangent *= -1;
    }

    if(_GSAA && !_GSAANormal) surf.perceptualRoughness = GSAA_Filament(worldNormal, surf.perceptualRoughness);

    surf.tangentNormal.g *= _NormalMapOrientation ? 1 : -1; // still need to figure out why its inverted by default
    worldNormal = normalize(surf.tangentNormal.x * tangent + surf.tangentNormal.y * bitangent + surf.tangentNormal.z * worldNormal);
    tangent = normalize(cross(worldNormal, bitangent));
    bitangent = normalize(cross(worldNormal, tangent));
    
    if(_GSAA && _GSAANormal) surf.perceptualRoughness = GSAA_Filament(worldNormal, surf.perceptualRoughness);


    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos.xyz);
    float NoV = abs(dot(worldNormal, viewDir)) + 1e-5;

    float3 pixelLight = 0;
    #ifdef USING_LIGHT_MULTI_COMPILE
        bool lightExists = any(_WorldSpaceLightPos0.xyz);
        float3 lightDirection = Unity_SafeNormalize(UnityWorldSpaceLightDir(i.worldPos.xyz));
        float3 lightHalfVector = Unity_SafeNormalize(lightDirection + viewDir);
        float lightNoL = saturate(dot(worldNormal, lightDirection));
        float lightLoH = saturate(dot(lightDirection, lightHalfVector));
        UNITY_LIGHT_ATTENUATION(lightAttenuation, i, i.worldPos.xyz);
        pixelLight = (lightNoL * lightAttenuation * _LightColor0.rgb) * Fd_Burley(surf.perceptualRoughness, NoV, lightNoL, lightLoH);
    #endif

    float3 vertexLight = 0;
    float3 vertexLightColor = 0;
    #if defined(VERTEXLIGHT_ON) && defined(UNITY_PASS_FORWARDBASE)
        initVertexLights(i.worldPos, worldNormal, vertexLight, vertexLightColor);
    #endif

    float3 indirectDiffuse = 1;
    #if defined(LIGHTMAP_ON)

        float2 lightmapUV = i.coord0.zw * unity_LightmapST.xy + unity_LightmapST.zw;
        float4 bakedColorTex = 0;

        float3 lightMap = tex2DFastBicubicLightmap(lightmapUV, bakedColorTex);

        #if defined(DIRLIGHTMAP_COMBINED)
            float4 lightMapDirection = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, lightmapUV);
            lightMap = DecodeDirectionalLightmap(lightMap, lightMapDirection, worldNormal);
        #endif

        #if defined(DYNAMICLIGHTMAP_ON)
            float3 realtimeLightMap = getRealtimeLightmap(i.coord1.xy, worldNormal, parallaxOffset);
            lightMap += realtimeLightMap; 
        #endif

        #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
            pixelLight = 0;
            vertexLight = 0;
            lightMap = SubtractMainLightWithRealtimeAttenuationFromLightmap (lightMap, lightAttenuation, bakedColorTex, worldNormal);
        #endif

        indirectDiffuse = lightMap;
    #else
        #ifdef NONLINEAR_LIGHTPROBESH
            float3 L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
            indirectDiffuse.r = shEvaluateDiffuseL1Geomerics_local(L0.r, unity_SHAr.xyz, worldNormal);
            indirectDiffuse.g = shEvaluateDiffuseL1Geomerics_local(L0.g, unity_SHAg.xyz, worldNormal);
            indirectDiffuse.b = shEvaluateDiffuseL1Geomerics_local(L0.b, unity_SHAb.xyz, worldNormal);
            indirectDiffuse = max(0, indirectDiffuse);
        #else
            indirectDiffuse = max(0, ShadeSH9(float4(worldNormal, 1)));
        #endif
    #endif

    #if defined(LIGHTMAP_SHADOW_MIXING) && defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) && defined(LIGHTMAP_ON)
        pixelLight *= UnityComputeForwardShadows(i.coord0.zw, i.worldPos, i.screenPos);
    #endif


    float3 indirectSpecular = 0;
    float3 directSpecular = 0;
    float3 f0 = 0.16 * surf.reflectance * surf.reflectance * (1 - surf.metallic) + surf.albedo.rgb * surf.metallic;
    float3 fresnel = lerp(f0, F_Schlick(NoV, f0), _FresnelIntensity) * _FresnelColor;
    fresnel *= saturate(pow(length(indirectDiffuse), _SpecularOcclusion));

    #ifdef ANISOTROPY
        #if defined(PROP_ANISOTROPYMAP)
            float3 anisotropicDirection = float3(_AnisotropyMap.Sample(defaultSampler, (i.coord0.xy * _AnisotropyMap_ST.xy + _AnisotropyMap_ST.zw)).rg, 1);
            float3 anisotropicT = normalize(tangent * anisotropicDirection);
            float3 anisotropicB = normalize(cross(worldNormal, anisotropicT));
        #else
            float3 anisotropicT = tangent;
            float3 anisotropicB = bitangent;
        #endif
    #endif
    
    #if defined(UNITY_PASS_FORWARDBASE)

        #if defined(REFLECTIONS)
            #ifndef ANISOTROPY
                float3 reflDir = reflect(-viewDir, worldNormal);
            #else
                float3 reflDir = getAnisotropicReflectionVector(viewDir, anisotropicB, anisotropicT, worldNormal, surf.perceptualRoughness);
            #endif

            Unity_GlossyEnvironmentData envData;
            envData.roughness = surf.perceptualRoughness;
            envData.reflUVW = getBoxProjection(reflDir, i.worldPos.xyz, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin.xyz, unity_SpecCube0_BoxMax.xyz);

            float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
            indirectSpecular = probe0;

            #if defined(UNITY_SPECCUBE_BLENDING)
                
                if (unity_SpecCube0_BoxMin.w < 0.99999)
                {
                    envData.reflUVW = getBoxProjection(reflDir, i.worldPos.xyz, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin.xyz, unity_SpecCube1_BoxMax.xyz);
                    float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, envData);
                    indirectSpecular = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);
                }
            #endif

            float horizon = min(1 + dot(reflDir, worldNormal), 1);
            indirectSpecular = indirectSpecular * lerp(fresnel, f0, surf.perceptualRoughness) * horizon * horizon;
        #endif

        indirectSpecular *= computeSpecularAO(NoV, surf.occlusion, surf.perceptualRoughness * surf.perceptualRoughness);
    #endif

    float clampedRoughness = max(surf.perceptualRoughness * surf.perceptualRoughness, 0.002);

    #if defined(SPECULAR_HIGHLIGHTS)
    {
        float NoH = saturate(dot(worldNormal, lightHalfVector));
        float3 F = F_Schlick(lightLoH, f0);

        #ifndef ANISOTROPY
            float D = GGXTerm(NoH, clampedRoughness);
            float V = V_SmithGGXCorrelated ( NoV, lightNoL, clampedRoughness);
        #else
            float anisotropy = _Anisotropy;
            float3 l = lightDirection;
            float3 t = anisotropicT;
            float3 b = anisotropicB;
            float3 v = viewDir;
            float3 h = lightHalfVector;

            float ToV = dot(t, v);
            float BoV = dot(b, v);
            float ToL = dot(t, l);
            float BoL = dot(b, l);
            float ToH = dot(t, h);
            float BoH = dot(b, h);

            half at = max(clampedRoughness * (1.0 + anisotropy), 0.002);
            half ab = max(clampedRoughness * (1.0 - anisotropy), 0.002);
            float D = D_GGX_Anisotropic(at, ab, ToH, BoH, NoH);
            float V = V_SmithGGXCorrelated_Anisotropic(at, ab, ToV, BoV, ToL, BoL, NoV, lightNoL);
        #endif

        directSpecular = max(0, (D * V) * F) * pixelLight * UNITY_PI;
    }
    #endif

    #if defined(BAKEDSPECULAR) && defined(UNITY_PASS_FORWARDBASE)
    {
        if(bakeryLightmapMode < 2)
        {
            float3 bakedDominantDirection = 1;
            float3 bakedSpecularColor = 0;

            #if defined(DIRLIGHTMAP_COMBINED) && defined(LIGHTMAP_ON)
                bakedDominantDirection = (lightMapDirection.xyz) * 2 - 1;
                bakedSpecularColor = indirectDiffuse;
            #endif

            #ifndef LIGHTMAP_ON
                bakedSpecularColor = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
                bakedDominantDirection = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
            #endif
                
            float3 bakedHalfDir = Unity_SafeNormalize(normalize(bakedDominantDirection) + viewDir);
            half nh = saturate(dot(worldNormal, bakedHalfDir));
            half bakedSpecular = D_GGX(nh, clampedRoughness);
            directSpecular += bakedSpecular * bakedSpecularColor * fresnel;
        }
    }
    #endif

    #if defined(BAKERY_RNM)
    if (bakeryLightmapMode == BAKERYMODE_RNM)
    {
        float3 eyeVecT = 0;
        #ifdef BAKERY_LMSPEC
            eyeVecT = -normalize(i.parallaxViewDir);
        #endif

        float3 prevSpec = indirectSpecular;
        BakeryRNM(indirectDiffuse, indirectSpecular, lightmapUV, surf.tangentNormal, surf.perceptualRoughness, eyeVecT);
        indirectSpecular *= fresnel;
        indirectSpecular += prevSpec;
    }
    #endif

    #ifdef BAKERY_SH
    if (bakeryLightmapMode == BAKERYMODE_SH)
    {
        float3 prevSpec = indirectSpecular;
        BakerySH(indirectDiffuse, indirectSpecular, lightmapUV, worldNormal, -viewDir, surf.perceptualRoughness);
        indirectSpecular *= fresnel;
        indirectSpecular += prevSpec;
    }
    #endif



    #if defined(_MODE_TRANSPARENT)
        surf.albedo.rgb *= surf.alpha;
        surf.alpha = lerp(surf.alpha, 1, surf.metallic);
    #endif

    float4 finalColor = float4(surf.albedo.rgb * (1 - surf.metallic) * (indirectDiffuse * surf.occlusion + (pixelLight + vertexLight)) + indirectSpecular + directSpecular + surf.emission, surf.alpha);

    #if defined (_MODE_FADE) && defined(UNITY_PASS_FORWARDADD)
        finalColor.rgb *= surf.alpha;
    #endif

    #ifdef UNITY_PASS_META
        UnityMetaInput metaInput;
        UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaInput);
        metaInput.Emission = surf.emission;
        metaInput.Albedo = surf.albedo.rgb;
        return float4(UnityMetaFragment(metaInput).rgb, surf.alpha);
    #endif

    #ifdef FOG
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
    #endif

    return finalColor;
#endif
}