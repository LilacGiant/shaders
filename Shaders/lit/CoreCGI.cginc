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

    #ifdef NEED_CENTROID_NORMAL
    if ( dot(i.worldNormal, i.worldNormal) >= 1.01 )
    {
        i.worldNormal = i.centroidWorldNormal;
    }
    #endif

    float3 worldNormal = i.worldNormal;
    float3 bitangent = i.bitangent;
    float3 tangent = i.tangent;

    float3 indirectSpecular = 0;
    float3 directSpecular = 0;

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

    #ifdef BAKERY_VOLUME
        float3 volumelpUV = (i.worldPos - (_VolumeMin.xyz)) * (_VolumeInvSize.xyz);
    #endif

    #ifdef BAKERY_VOLUME
        _LightColor0.rgb *= saturate(dot(_VolumeMask.Sample(sampler_Volume0, volumelpUV), unity_OcclusionMaskSelector));
    #endif

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

        #ifdef BAKERY_VOLUME
        
            float4 tex0, tex1, tex2;
            float3 L0, L1x, L1y, L1z;
            tex0 = _Volume0.Sample(sampler_Volume0, volumelpUV);
            tex1 = _Volume1.Sample(sampler_Volume0, volumelpUV);
            tex2 = _Volume2.Sample(sampler_Volume0, volumelpUV);
            L0 = tex0.xyz;
            L1x = tex1.xyz;
            L1y = tex2.xyz;
            L1z = float3(tex0.w, tex1.w, tex2.w);
            indirectDiffuse.r = shEvaluateDiffuseL1Geomerics(L0.r, float3(L1x.r, L1y.r, L1z.r), worldNormal);
            indirectDiffuse.g = shEvaluateDiffuseL1Geomerics(L0.g, float3(L1x.g, L1y.g, L1z.g), worldNormal);
            indirectDiffuse.b = shEvaluateDiffuseL1Geomerics(L0.b, float3(L1x.b, L1y.b, L1z.b), worldNormal);
        
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

            if(_EnableOcclusionProbes)
            {
                float occlusionProbes = SampleOcclusionProbes(i.worldPos);
                indirectDiffuse *= occlusionProbes;
            }
        #endif
    #endif

    #if defined(LIGHTMAP_SHADOW_MIXING) && defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) && defined(LIGHTMAP_ON)
        pixelLight *= UnityComputeForwardShadows(i.coord0.zw, i.worldPos, i.screenPos);
    #endif


    
    float3 f0 = 0.16 * surf.reflectance * surf.reflectance * (1 - surf.metallic) + surf.albedo.rgb * surf.metallic;
    float3 fresnel = lerp(f0, F_Schlick(NoV, f0), _FresnelIntensity) * _FresnelColor;
    fresnel *= saturate(pow(length(indirectDiffuse), _SpecularOcclusion));

    #ifdef ANISOTROPY
        float3 anisotropicDirection = float3(surf.anisotropicDirection, 1);
        float3 anisotropicT = normalize(tangent * anisotropicDirection);
        float3 anisotropicB = normalize(cross(worldNormal, anisotropicT));
    #endif
    
    #if defined(UNITY_PASS_FORWARDBASE)

        #if defined(REFLECTIONS)
            #ifndef ANISOTROPY
                float3 reflDir = reflect(-viewDir, worldNormal);
            #else
                float3 reflDir = getAnisotropicReflectionVector(viewDir, anisotropicB, anisotropicT, worldNormal, surf.perceptualRoughness, surf.anisotropy);
            #endif

            Unity_GlossyEnvironmentData envData;
            envData.roughness = surf.perceptualRoughness;
            envData.reflUVW = getBoxProjection(reflDir, i.worldPos.xyz, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin.xyz, unity_SpecCube0_BoxMax.xyz);

            float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
            indirectSpecular = probe0;

            #if defined(UNITY_SPECCUBE_BLENDING)
                UNITY_BRANCH
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
            float anisotropy = surf.anisotropy;
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

        directSpecular += max(0, (D * V) * F) * pixelLight * UNITY_PI;
    }
    #endif

    #if defined(BAKEDSPECULAR) && defined(BAKERY_VOLUME)
        float3 nL1x = L1x / L0;
        float3 nL1y = L1y / L0;
        float3 nL1z = L1z / L0;
        float3 dominantDir = float3(dot(nL1x, lumaConv), dot(nL1y, lumaConv), dot(nL1z, lumaConv));
        half3 halfDir = Unity_SafeNormalize(normalize(dominantDir) + viewDir);
        half nh = saturate(dot(worldNormal, halfDir));
        half spec = GGXTerm(nh, clampedRoughness);
        float3 sh = L0 + dominantDir.x * L1x + dominantDir.y * L1y + dominantDir.z * L1z;
        directSpecular += max(spec * sh, 0.0) * fresnel;
    #endif

    #if defined(BAKEDSPECULAR) && defined(UNITY_PASS_FORWARDBASE) && !defined(BAKERY_VOLUME)
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
                bakedSpecularColor = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w) * UNITY_PI;
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

    


    directSpecular *= _SpecularIntensity;
    

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

    #ifdef NEED_FOG
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
    #endif

    return finalColor;
#endif
}