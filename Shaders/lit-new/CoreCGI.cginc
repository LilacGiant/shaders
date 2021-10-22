float4 frag (v2f i, bool facing : SV_IsFrontFace) : SV_Target
{
    input = i;
    
    float4 mainTexture = SampleTexture(_MainTex, _MainTex_ST, sampler_MainTex, _MainTex_UV) * _Color;
    float alpha = mainTexture.a;

#if defined(UNITY_PASS_SHADOWCASTER)

    #if defined(_MODE_CUTOUT) || defined (_MODE_A2C_SHARPENED)
    if(alpha < _Cutoff) discard;
    #endif

    #if defined (_MODE_A2C)
    if(alpha < 0.001) discard;
    #endif

    #if defined (_MODE_FADE) || defined (_MODE_TRANSPARENT)
    if(alpha < 0.5) discard;
    #endif

    SHADOW_CASTER_FRAGMENT(i);
#else
    #if defined(_MODE_CUTOUT)
    if(alpha < _Cutoff) discard;
    #endif

    #if defined (_MODE_A2C_SHARPENED)
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
    #ifdef NEED_TANGENT_BITANGENT
        float3 bitangent = i.bitangent;
        float3 tangent = i.tangent;
    #endif
    if(!facing)
    {
        worldNormal *= -1;
        #ifdef NEED_TANGENT_BITANGENT
            bitangent *= -1;
            tangent *= -1;
        #endif
    }
    

    float4 maskMap = 1;
    float metallicMap = 1;
    float smoothnessMap = 1;
    float occlusionMap = 1;
    bool isRoughness = _GlossinessInvert;

    #ifdef _WORKFLOW_UNPACKED

        #ifdef PROP_METALLICMAP
            metallicMap = SampleTexture(_MetallicMap, _MetallicMap_ST, _MetallicMap_UV);
        #endif

        #ifdef PROP_SMOOTHNESSMAP
            smoothnessMap = SampleTexture(_SmoothnessMap, _SmoothnessMap_ST, _SmoothnessMap_UV);
        #endif

        #ifdef PROP_OCCLUSIONMAP
            occlusionMap = SampleTexture(_OcclusionMap, _OcclusionMap_ST, _OcclusionMap_UV);
        #endif

    #else

        #ifdef PROP_METALLICGLOSSMAP
            maskMap = SampleTexture(_MetallicGlossMap, _MetallicGlossMap_ST, _MetallicGlossMap_UV);
        #endif
        
        metallicMap = maskMap.r;
        smoothnessMap = maskMap.a;
        occlusionMap = maskMap.g;
        isRoughness = 0;
    #endif

    float smoothness = _Glossiness * smoothnessMap;
    perceptualRoughness = isRoughness ? smoothness : 1-smoothness;
    metallic = metallicMap * _Metallic * _Metallic;
    occlusion = lerp(1,occlusionMap , _Occlusion);

    UNITY_BRANCH
    if(_GSAA) perceptualRoughness = GSAA_Filament(worldNormal, perceptualRoughness);

    #ifdef PROP_BUMPMAP
        float4 normalMap = SampleTexture(_BumpMap, _BumpMap_ST, sampler_BumpMap, _BumpMap_UV);
        #define CALC_TANGENT_BITANGENT
    #else 
        float4 normalMap = float4(0.5, 0.5, 1, 1);
    #endif

    #if defined(CALC_TANGENT_BITANGENT) && defined(NEED_TANGENT_BITANGENT)
        float3 tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);

        tangentNormal.g *= _NormalMapOrientation ? 1 : -1;

        half3 calcedNormal = normalize
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
        #if defined(NEED_TANGENT_BITANGENT)
            tangent = normalize(bitangent);
            bitangent = normalize(tangent);
        #endif
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
        indirectDiffuse = max(0, ShadeSH9(float4(worldNormal, 1)));
    #endif



    float3 f0 = 0.16 * _Reflectance * _Reflectance * (1 - metallic) + mainTexture.rgb * metallic;
    float3 fresnel = lerp(f0, F_Schlick(NoV, f0) , _FresnelIntensity);
    fresnel *= lerp(1, saturate(pow(length(indirectDiffuse), _SpecularOcclusion)), _SpecularOcclusion);
    
    #if defined(UNITY_PASS_FORWARDBASE)

        #if defined(REFLECTIONS)
            float3 reflDir = reflect(-viewDir, worldNormal);
            
            // if(_EnableAnisotropy) reflViewDir = getAnisotropicReflectionVector(viewDir, bitangent, tangent, worldNormal, surface.perceptualRoughness);
            Unity_GlossyEnvironmentData envData;
            envData.roughness = perceptualRoughness;
            envData.reflUVW = getBoxProjection(reflDir, i.worldPos.xyz, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);

            float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
            indirectSpecular = probe0;

            #if defined(UNITY_SPECCUBE_BLENDING)
                UNITY_BRANCH
                if (unity_SpecCube0_BoxMin.w < 0.99999)
                {
                    envData.reflUVW = getBoxProjection(reflDir, i.worldPos.xyz, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
                    float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, envData);
                    indirectSpecular = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);
                }
            #endif

            float horizon = min(1 + dot(reflDir, worldNormal), 1);
            indirectSpecular = indirectSpecular * lerp(fresnel, f0, perceptualRoughness) * horizon * horizon;

        #endif

        indirectSpecular *= computeSpecularAO(NoV, occlusion, perceptualRoughness * perceptualRoughness);
    #endif

    #if defined(SPECULAR_HIGHLIGHTS)
        float NoH = saturate(dot(worldNormal, lightHalfVector));
        half roughness = max(perceptualRoughness * perceptualRoughness, 0.002);

        #ifndef ANISOTROPY
            float3 F = F_Schlick(lightLoH, f0);
            float D = GGXTerm(NoH, roughness);
            float V = V_SmithGGXCorrelated ( NoV, lightNoL, roughness);
        #endif
        
        directSpecular += max(0, (D * V) * F) * pixelLight * UNITY_PI;
    #endif






    #ifdef EMISSION
        float3 emissionMap = 1;
        #ifdef PROP_EMISSIONMAP
        emissionMap = SampleTexture(_EmissionMap, _EmissionMap_ST, _EmissionMap_UV).rgb;
        #endif
        if(_EmissionMultBase) emissionMap *= mainTexture.rgb;
        emission = emissionMap * pow(_EmissionColor, 2.2);
    #endif

    
    // alpha -= mainTexture.a * 0.00001;
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