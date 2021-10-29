float4 frag (v2f i, uint facing : SV_IsFrontFace) : SV_Target
{
    input = i;
    #if defined(PARALLAX)
        parallaxOffset = ParallaxOffset(i.parallaxViewDir);
    #endif

    #if defined(TEXTUREARRAY)
        defaultSampler = sampler_MainTexArray;
        #ifdef INSTANCING_ON
            textureIndex = UNITY_ACCESS_INSTANCED_PROP(Props, _TextureIndex);
        #else
            textureIndex = i.coord1.z;
        #endif
        float4 mainTexture = SampleTextureArray(_MainTexArray, _MainTex_ST, _MainTex_UV);
    #else
        defaultSampler = sampler_MainTex;
        float4 mainTexture = SampleTexture(_MainTex, _MainTex_ST, defaultSampler, _MainTex_UV);
    #endif

    mainTexture *= _Color;
    float alpha = mainTexture.a;

#if defined(UNITY_PASS_SHADOWCASTER)

    #if defined(_MODE_CUTOUT)
    if(alpha < _Cutoff) discard;
    #endif

    #if defined (_MODE_FADE) || defined (_MODE_TRANSPARENT)
    if(alpha < 0.5) discard;
    #endif

    SHADOW_CASTER_FRAGMENT(i);
#else
    #if defined (_MODE_CUTOUT)
    alpha = (alpha - _Cutoff) / max(fwidth(alpha), 0.0001) + 0.5;
    #endif

    float3 emission = 0;
    float perceptualRoughness = 0.5;
    float metallic = 0;
    float occlusion = 1;
    float3 indirectDiffuse = 1;
    float3 pixelLight = 0;
    float3 vertexLight = 0;
    float3 indirectSpecular = 0;
    float3 directSpecular = 0;

    float3 worldNormal = i.worldNormal;
    float3 bitangent = i.bitangent;
    float3 tangent = i.tangent;

    if(!facing)
    {
        worldNormal *= -1;
        bitangent *= -1;
        tangent *= -1;
    }
    

    float4 maskMap = 1;
    float metallicMap = 1;
    float smoothnessMap = 1;
    float occlusionMap = 1;

    #ifdef _WORKFLOW_UNPACKED

        #ifdef PROP_METALLICMAP
            metallicMap = SampleTexture(_MetallicMap, _MetallicMap_ST, _MetallicMap_UV);
        #endif

        #ifdef PROP_SMOOTHNESSMAP
            smoothnessMap = SampleTexture(_SmoothnessMap, _SmoothnessMap_ST, _SmoothnessMap_UV);
            smoothnessMap = _GlossinessInvert ? 1-smoothnessMap : smoothnessMap;
        #endif

        #ifdef PROP_OCCLUSIONMAP
            occlusionMap = SampleTexture(_OcclusionMap, _OcclusionMap_ST, _OcclusionMap_UV);
        #endif

    #else
        #if defined(PROP_METALLICGLOSSMAP) && !defined(TEXTUREARRAYMASK)
            maskMap = SampleTexture(_MetallicGlossMap, _MetallicGlossMap_ST, _MetallicGlossMap_UV);
        #endif

        #if defined(TEXTUREARRAYMASK)
            maskMap = SampleTextureArray(_MetallicGlossMapArray, _MetallicGlossMap_ST, _MetallicGlossMap_UV);
        #endif
        
        metallicMap = maskMap.r;
        smoothnessMap = maskMap.a;
        occlusionMap = maskMap.g;
    #endif

    float smoothness = _Glossiness * smoothnessMap;
    perceptualRoughness = 1-smoothness;
    metallic = metallicMap * _Metallic * _Metallic;
    occlusion = lerp(1,occlusionMap , _Occlusion);

    #if defined(PROP_DETAILMAP)

        #if defined(PROP_DETAILMAP)
            float4 detailMap = SampleTexture(_DetailMap, _DetailMap_ST, _DetailMap_UV);
        #endif

        float detailMask = maskMap.a;
        float detailAlbedo = detailMap.r * 2.0 - 1.0;
        float detailSmoothness = (detailMap.b * 2.0 - 1.0);

        // Goal: we want the detail albedo map to be able to darken down to black and brighten up to white the surface albedo.
        // The scale control the speed of the gradient. We simply remap detailAlbedo from [0..1] to [-1..1] then perform a lerp to black or white
        // with a factor based on speed.
        // For base color we interpolate in sRGB space (approximate here as square) as it get a nicer perceptual gradient

        float albedoDetailSpeed = saturate(abs(detailAlbedo) * _DetailAlbedoScale);
        float3 baseColorOverlay = lerp(sqrt(mainTexture.rgb), (detailAlbedo < 0.0) ? float3(0.0, 0.0, 0.0) : float3(1.0, 1.0, 1.0), albedoDetailSpeed * albedoDetailSpeed);
        baseColorOverlay *= baseColorOverlay;							   
        // Lerp with details mask
        mainTexture.rgb = lerp(mainTexture.rgb, saturate(baseColorOverlay), detailMask);

        float perceptualSmoothness = (1 - perceptualRoughness);
        // See comment for baseColorOverlay
        float smoothnessDetailSpeed = saturate(abs(detailSmoothness) * _DetailSmoothnessScale);
        float smoothnessOverlay = lerp(perceptualSmoothness, (detailSmoothness < 0.0) ? 0.0 : 1.0, smoothnessDetailSpeed);
        // Lerp with details mask
        perceptualSmoothness = lerp(perceptualSmoothness, saturate(smoothnessOverlay), detailMask);

        perceptualRoughness = (1 - perceptualSmoothness);
        #ifndef CALC_TANGENT_BITANGENT
        #define CALC_TANGENT_BITANGENT
        #endif
    #endif

    mainTexture.rgb = lerp(dot(mainTexture.rgb, grayscaleVec), mainTexture.rgb, _Saturation + 1);

    UNITY_BRANCH
    if(_GSAA) perceptualRoughness = GSAA_Filament(worldNormal, perceptualRoughness);

    float4 normalMap = float4(0.5, 0.5, 1, 1);

    #if defined(PROP_BUMPMAP) && !defined(TEXTUREARRAYBUMP)
        normalMap = SampleTexture(_BumpMap, _BumpMap_ST, sampler_BumpMap, _BumpMap_UV);
        #ifndef CALC_TANGENT_BITANGENT
        #define CALC_TANGENT_BITANGENT
        #endif
    #endif

    #if defined(TEXTUREARRAYBUMP)
        normalMap = SampleTextureArray(_BumpMapArray, _BumpMap_ST, _BumpMap_UV);
        #ifndef CALC_TANGENT_BITANGENT
        #define CALC_TANGENT_BITANGENT
        #endif
    #endif
    

    #if defined(CALC_TANGENT_BITANGENT) && defined(NEED_TANGENT_BITANGENT)
        float3 tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);

        #if defined(PROP_DETAILMAP)
            float4 detailNormalMap = float4(detailMap.a, detailMap.g, 1, 1);
            detailNormalMap.g = 1-detailNormalMap.g;
            float3 detailNormal = UnpackScaleNormal(detailNormalMap, _DetailNormalScale);
            tangentNormal = BlendNormals(tangentNormal, detailNormal);
        #endif

        tangentNormal.g *= _NormalMapOrientation ? 1 : -1;

        float3 calcedNormal = normalize
        (
            tangentNormal.x * tangent +
            tangentNormal.y * bitangent +
            tangentNormal.z * worldNormal
        );

        worldNormal = calcedNormal;
        tangent = normalize(cross(worldNormal, bitangent));
        bitangent = normalize(cross(worldNormal, tangent));

        
    #else
        worldNormal = normalize(worldNormal);
        tangent = normalize(tangent);
        bitangent = normalize(bitangent);
    #endif

    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos.xyz);
    float NoV = abs(dot(worldNormal, viewDir)) + 1e-5;

    #ifdef USING_LIGHT_MULTI_COMPILE
        float3 lightDirection = Unity_SafeNormalize(UnityWorldSpaceLightDir(i.worldPos.xyz));
        float3 lightHalfVector = Unity_SafeNormalize(lightDirection + viewDir);
        float lightNoL = saturate(dot(worldNormal, lightDirection));
        float lightLoH = saturate(dot(lightDirection, lightHalfVector));
        LIGHT_ATTENUATION_NO_SHADOW_MUL(lightAttenNoShadows, i, i.worldPos.xyz);
        float3 lightAttenuation = lightAttenNoShadows * shadow;
        pixelLight = (lightNoL * lightAttenuation * _LightColor0.rgb) * Fd_Burley(perceptualRoughness, NoV, lightNoL, lightLoH);
    #endif


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



    float3 f0 = 0.16 * _Reflectance * _Reflectance * (1 - metallic) + mainTexture.rgb * metallic;
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
                float3 reflDir = getAnisotropicReflectionVector(viewDir, anisotropicB, anisotropicT, worldNormal, perceptualRoughness);
            #endif

            Unity_GlossyEnvironmentData envData;
            envData.roughness = perceptualRoughness;
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
            indirectSpecular = indirectSpecular * lerp(fresnel, f0, perceptualRoughness) * horizon * horizon;

        #endif

        indirectSpecular *= computeSpecularAO(NoV, occlusion, perceptualRoughness * perceptualRoughness);
    #endif

    float clampedRoughness = max(perceptualRoughness * perceptualRoughness, 0.002);

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
        
        directSpecular += max(0, (D * V) * F) * pixelLight * UNITY_PI;
    }
    #endif

    #ifdef BAKEDSPECULAR
    {
        float3 bakedDominantDirection = 1;
        float3 bakedSpecularColor = 0;

        #if !defined(BAKERY_SH) && !defined(BAKERY_RNM)

            #ifdef DIRLIGHTMAP_COMBINED
                bakedDominantDirection = (lightMapDirection.xyz) * 2 - 1;
                bakedSpecularColor = indirectDiffuse;
            #endif

            #ifndef LIGHTMAP_ON
                bakedSpecularColor = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
                bakedDominantDirection = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
            #endif
            
        #endif

        float3 bakedHalfDir = Unity_SafeNormalize(normalize(bakedDominantDirection) + viewDir);
        half nh = saturate(dot(worldNormal, bakedHalfDir));
        half bakedSpecular = D_GGX(nh, clampedRoughness);
        directSpecular += bakedSpecular * bakedSpecularColor * fresnel;
    }
    #endif






    #ifdef EMISSION
        float3 emissionMap = 1;
        #ifdef PROP_EMISSIONMAP
        emissionMap = SampleTexture(_EmissionMap, _EmissionMap_ST, _EmissionMap_UV).rgb;
        #endif
        if(_EmissionMultBase) emissionMap *= mainTexture.rgb;
        emission = emissionMap * pow(_EmissionColor, 2.2);
    #endif

    
    #if defined(_MODE_TRANSPARENT)
        mainTexture.rgb *= alpha;
        alpha = lerp(alpha, 1, metallic);
    #endif

    float4 finalColor = float4(mainTexture.rgb * (1 - metallic) * (indirectDiffuse * occlusion + (pixelLight + vertexLight)) + indirectSpecular + directSpecular + emission, alpha);

    #if defined (_MODE_FADE) && defined(UNITY_PASS_FORWARDADD)
        finalColor.rgb *= alpha;
    #endif

    #ifdef FOG
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
    #endif

    return finalColor;
#endif
}