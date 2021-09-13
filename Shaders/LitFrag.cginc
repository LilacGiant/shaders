#if !defined(UNITY_PASS_SHADOWCASTER)
half4 frag(v2f i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    #if defined(LOD_FADE_CROSSFADE)
		UnityApplyDitherCrossFade(i.pos);
	#endif

    initUVs(i);
    float3 worldPos = i.worldPos;
    half2 parallaxOffset = 0;
    half alpha = 1;
    half4 maskMap = 1;
    half4 detailMap = 1;
    half metallicMap = 1;
    half smoothnessMap = 1;
    half occlusionMap = 1;
    half4 mainTex = 1;
    float3 tangentNormal = 0.5;
    half2 lightmapUV = 0;
    float3 vLight = 0;
    float3 vertexLightColor = 0;



    float3 worldNormal = normalize(i.worldNormal);
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    half NoV = abs(dot(worldNormal, viewDir)) + 1e-5;

    
    #if defined(ENABLE_PARALLAX)
        parallaxOffset = ParallaxOffset(i.viewDirForParallax);
    #endif

    getMainTex(mainTex, parallaxOffset, i.color);

    
    #ifdef ENABLE_TRANSPARENCY
        alpha = calcAlpha(surface.albedo.a);
    #endif


    initSurfaceData(metallicMap, smoothnessMap, occlusionMap, maskMap, parallaxOffset);

    #if defined(PROP_DETAILMAP)
        detailMap = applyDetailMap(parallaxOffset, maskMap.a);
    #endif

    applySaturation();


    #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (PROP_BUMPMAP) || defined(UNITY_PASS_META)
        half3 tangent = i.tangent;
        half3 bitangent = i.bitangent;
    #endif


    #ifdef PROP_BUMPMAP
        half4 normalMap = _BumpMap.Sample(sampler_BumpMap, TRANSFORMTEX(uvs[_BumpMapUV], _BumpMap_ST, _MainTex_ST));
        float4 detailNormalMap = float4(0.5, 0.5, 1, 1);
        #if defined(PROP_DETAILMAP)
            detailNormalMap = float4(detailMap.a, detailMap.g, 1, 1);
        #endif
        initNormalMap(normalMap, bitangent, tangent, worldNormal, detailNormalMap, tangentNormal);
    #endif
    

    #if !defined(LIGHTMAP_ON) || defined(USING_LIGHT_MULTI_COMPILE)
        initLighting(i, worldNormal, viewDir, NoV);
    #endif

    #if defined(VERTEXLIGHT_ON) && defined(UNITY_PASS_FORWARDBASE)
        initVertexLights(worldPos, worldNormal, vLight, vertexLightColor);
    #endif


    getIndirectDiffuse(worldNormal, parallaxOffset, lightmapUV);

    #if defined(ENABLE_GSAA)
        surface.perceptualRoughness = GSAA_Filament(worldNormal, surface.perceptualRoughness);
    #endif

    #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined(UNITY_PASS_META) || defined(BAKERY_INCLUDED)
        half3 f0 = 0.16 * _Reflectance * _Reflectance * surface.oneMinusMetallic + surface.albedo * surface.metallic;
        half3 fresnel = F_Schlick(NoV, f0);

        fresnel = lerp(f0, fresnel , _FresnelColor.a);
        fresnel *= _FresnelColor.rgb;
        fresnel *= _SpecularOcclusion ? saturate(lerp(1, pow(length(light.indirectDiffuse), _SpecularOcclusion), _SpecularOcclusion * surface.oneMinusMetallic)) : 1;
    #endif

    #if defined(UNITY_PASS_FORWARDBASE)

        #if defined(ENABLE_REFLECTIONS)
            float3 reflViewDir = reflect(-viewDir, worldNormal);
            float3 reflWorldNormal = worldNormal;

            if(_Anisotropy != 0) reflViewDir = getAnisotropicReflectionVector(viewDir, bitangent, tangent, worldNormal, surface.perceptualRoughness);
            light.indirectSpecular = getIndirectSpecular(reflViewDir, worldPos, reflWorldNormal, fresnel, f0);
        #endif

        light.indirectSpecular *= computeSpecularAO(NoV, surface.occlusion, surface.perceptualRoughness * surface.perceptualRoughness);
    #endif

    #if defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined(UNITY_PASS_META)
        light.directSpecular = getDirectSpecular(worldNormal, tangent, bitangent, f0, NoV);
    #endif

    
    #if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_META)
        applyEmission(parallaxOffset);
    #endif

    #if defined(BAKERY_RNM)
        if (bakeryLightmapMode == BAKERYMODE_RNM)
        {
            float3 eyeVecT = 0;
            #ifdef BAKERY_LMSPEC
                eyeVecT = -normalize(i.viewDirForParallax);
            #endif

            float3 prevSpec = light.indirectSpecular;
            BakeryRNM(light.indirectDiffuse, light.indirectSpecular, lightmapUV, tangentNormal, surface.perceptualRoughness, eyeVecT);
            light.indirectSpecular *= fresnel;
            light.indirectSpecular += prevSpec;
        }
    #endif

    #ifdef BAKERY_SH
    if (bakeryLightmapMode == BAKERYMODE_SH)
    {
        float3 prevSpec = light.indirectSpecular;
        BakerySH(light.indirectDiffuse, light.indirectSpecular, lightmapUV, worldNormal, -viewDir, surface.perceptualRoughness);
        light.indirectSpecular *= fresnel;
        light.indirectSpecular += prevSpec;
    }
    #endif
    
    alpha -= mainTex.a * 0.00001; // fix main tex sampler without changing the color;
    if(_Mode == 3)
    {
        surface.albedo.rgb *= alpha;
        alpha = lerp(alpha, 1, surface.metallic);
    }

    if(_FlatShading) light.finalLight = saturate(light.color + vertexLightColor) * light.attenuation;

    half4 finalColor = half4( surface.albedo * surface.oneMinusMetallic * ((light.indirectDiffuse * surface.occlusion) + (light.finalLight + vLight)) + light.directSpecular + light.indirectSpecular + surface.emission, alpha);

    #ifdef UNITY_PASS_META
        return getMeta(surface, light, alpha);
    #endif

    #ifdef USE_FOG
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
    #endif

    return finalColor;
}
#endif

#if defined(UNITY_PASS_SHADOWCASTER)
half4 ShadowCasterfrag(v2f i) : SV_Target
{
    #if defined(LOD_FADE_CROSSFADE)
		UnityApplyDitherCrossFade(i.pos);
	#endif
    
    initUVs(i);
    half2 parallaxOffset = 0;
    half4 mainTex = MAIN_TEX(_MainTex, sampler_MainTex, uvs[_MainTexUV], _MainTex_ST);

    half alpha = mainTex.a * _Color.a;

    #ifdef ENABLE_TRANSPARENCY // todo dithering
        if(_Mode == 1) clip(alpha - _Cutoff);
        if(_Mode > 1) clip(alpha-0.5);
    #endif

    SHADOW_CASTER_FRAGMENT(i);
}
#endif