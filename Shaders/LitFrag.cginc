#ifndef LITFRAG
#define LITFRAG

half4 frag(v2f i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i); 
    initUVs(i);

    half4 mainTex = MAIN_TEX(_MainTex, sampler_MainTex, uvs[_MainTexUV], _MainTex_ST);

    half intensity = dot(mainTex, grayscaleVec); // saturation
    mainTex.rgb = lerp(intensity, mainTex.rgb, (_Saturation+1));

    surface.albedo = mainTex * _Color;

    half4 vertexColor = 1;
    #ifdef ENABLE_VERTEXCOLOR
        vertexColor = i.color;
        surface.albedo.rgb *= _EnableVertexColor ? GammaToLinearSpace(vertexColor) : 1;
    #endif
    
    half alpha = 1;
    #ifdef ENABLE_TRANSPARENCY
        alpha = calcAlpha(_Cutoff,surface.albedo.a);
        if(_Mode!=1 && _Mode!=0) surface.albedo.rgb *= _Color.a;
    #endif

    
    half isRoughness = _GlossinessInvert;
    half4 maskMap = 1;
    half4 detailMap = 1;
    half metallicMap = 1;
    half smoothnessMap = 1;
    half occlusionMap = 1;

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
            #define PROP_SMOOTHNESSMAP
            #define PROP_OCCLUSIONMAP
            #define PROP_METALLICMAP
            maskMap = NOSAMPLER_TEX(_MetallicGlossMap, uvs[_MetallicGlossMapUV], _MetallicGlossMap_ST, _MainTex_ST);
        #endif
        
        metallicMap = maskMap.r;
        smoothnessMap = maskMap.a;
        occlusionMap = maskMap.g;
        isRoughness = 0;
    #endif

/*
    #if defined(PROP_DETAILMAP) && defined(PROP_METALLICGLOSSMAP)
    detailMap = _DetailMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_DetailMapUV], _DetailMap_ST, _MainTex_ST));
    detailMap *= 1 - maskMap.b;
    surface.albedo.rgb = ( surface.albedo.rgb * maskMap.bbb ) + BlendMode_Overlay(surface.albedo.rgb, detailMap.rrr);
    
    #endif
*/
    half smoothness = _Glossiness * smoothnessMap;
    surface.perceptualRoughness = isRoughness ? smoothness : 1-smoothness;
    surface.metallic = metallicMap * _Metallic * _Metallic;
    surface.occlusion = lerp(1,occlusionMap , _Occlusion);


    if(_EnableVertexColorMask)
    {
        surface.metallic *= vertexColor.r;
        surface.perceptualRoughness *= vertexColor.a;
        surface.occlusion *= vertexColor.g;
    }

    
    half3 worldNormal = i.worldNormal;
    #ifndef SHADER_API_MOBILE
        worldNormal = normalize(worldNormal);
    #endif

    #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (PROP_BUMPMAP)
        half3 tangent = i.tangent;
        half3 bitangent = i.bitangent;
    #endif


    #ifdef PROP_BUMPMAP
        half4 normalMap = _BumpMap.Sample(sampler_BumpMap, TRANSFORMTEX(uvs[_BumpMapUV], _BumpMap_ST, _MainTex_ST));
        initNormalMap(normalMap, bitangent, tangent, worldNormal, _BumpScale, _NormalMapOrientation);
    #endif


    half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    half NoV = abs(dot(worldNormal, viewDir)) + 1e-5;
    

    #if !defined(LIGHTMAP_ON) || defined(USING_LIGHT_MULTI_COMPILE)
        light.indirectDominantColor = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
        light.direction = getLightDir(!_GetDominantLight, i.worldPos);
        light.color = getLightCol(!_GetDominantLight, _LightColor0.rgb, light.indirectDominantColor) * 0.95;
        light.halfVector = normalize(light.direction + viewDir);
        light.NoL = saturate(dot(worldNormal, light.direction));
        light.LoH = saturate(dot(light.direction, light.halfVector));
        UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
        light.attenuation = attenuation;
        light.finalLight = (light.NoL * light.attenuation * light.color);
        #ifndef SHADER_API_MOBILE
            light.finalLight *= Fd_Burley(surface.perceptualRoughness, NoV, light.NoL, light.LoH);
        #endif
    #endif


    light.directDiffuse = surface.albedo.rgb * (1 - surface.metallic);
    #if defined(LIGHTMAP_ON)
        half3 lightMap = getLightmap(uvs[1], worldNormal);
        #if defined(DYNAMICLIGHTMAP_ON)
            half3 realtimeLightMap = getRealtimeLightmap(uvs[2], worldNormal);
        lightMap +=realtimeLightMap; 
        #endif
        light.indirectDiffuse = lightMap;
        #else
        light.indirectDiffuse = getIndirectDiffuse(worldNormal);
    #endif


    #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS)
        half3 f0 = 0.16 * _Reflectance * _Reflectance * (1 - surface.metallic) + surface.albedo * surface.metallic;
        half3 fresnel = F_Schlick(f0, NoV);
        fresnel = lerp(f0, fresnel , _FresnelColor.a); // kill fresnel
        fresnel *= _FresnelColor.rgb;
        fresnel *= _SpecularOcclusion ? saturate(lerp(1, pow(length(light.indirectDiffuse), _SpecularOcclusion), _SpecularOcclusion * (1 - surface.metallic))) : 1; // lightmap surface.occlusion

        #if !defined(SHADER_API_MOBILE)
            #if defined(ENABLE_GSAA)
                surface.perceptualRoughness = GSAA_Filament(worldNormal, surface.perceptualRoughness);
            #endif
        #endif

    #endif


    #if defined(UNITY_PASS_FORWARDBASE)

        #if defined(ENABLE_REFLECTIONS)
            half3 reflViewDir = reflect(-viewDir, worldNormal);
            if(_Anisotropy != 0) reflViewDir = getAnisotropicReflectionVector(viewDir, bitangent, tangent, worldNormal, surface.perceptualRoughness, _Anisotropy);
            light.indirectSpecular = getIndirectSpecular(surface.metallic, surface.perceptualRoughness, reflViewDir, i.worldPos, light.directDiffuse, worldNormal);
            light.indirectSpecular *= lerp(fresnel, f0, surface.perceptualRoughness);
        #endif

        #if defined(ENABLE_MATCAP)
            light.indirectSpecular = lerp(light.indirectSpecular, _MatCap.Sample(sampler_MainTex, mul((float3x3)UNITY_MATRIX_V, worldNormal).xy * 0.5 + 0.5).rgb, _MatCapReplace);
        #endif

        #if defined(PROP_OCCLUSIONMAP)
            light.indirectSpecular *= computeSpecularAO(NoV, surface.occlusion, surface.perceptualRoughness * surface.perceptualRoughness);
        #endif

    #endif


    #ifdef ENABLE_SPECULAR_HIGHLIGHTS
        half NoH = saturate(dot(worldNormal, light.halfVector));
        light.directSpecular = getDirectSpecular(surface.perceptualRoughness, NoH, NoV, light.NoL, light.LoH, f0, _Anisotropy, light.halfVector, tangent, bitangent) * light.finalLight;
    #endif


    
    #if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_META)

        half3 emissionMap = 1;
        #if defined(PROP_EMISSIONMAP)
            emissionMap = _EmissionMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_EmissionMapUV], _EmissionMap_ST, _MainTex_ST)).rgb;
        #endif

        surface.emission = _EnableEmission ? emissionMap * pow(_EmissionColor.rgb, 2.2) : 0;
    #endif


    half3 finalColor = light.directDiffuse * ((light.indirectDiffuse * surface.occlusion) + light.finalLight) + light.directSpecular + light.indirectSpecular + surface.emission;


    alpha -= mainTex.a * 0.00001; // fix main tex sampler without changing the color;


    #ifdef UNITY_PASS_META
        UnityMetaInput metaInput;
        UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaInput);
        metaInput.Emission = surface.emission;
        metaInput.Albedo = surface.albedo;
        metaInput.SpecularColor = light.directSpecular;
        if(_Mode == 1) clip(alpha - _Cutoff);
        return float4(UnityMetaFragment(metaInput).rgb, alpha);
    #endif


    half4 col = half4(finalColor, alpha);
    
    #ifdef USE_FOG
        UNITY_APPLY_FOG(i.fogCoord, col);
    #endif

    if(_TonemappingMode) col.rgb = lerp(col.rgb, ACESFilm(col.rgb), _Contribution); // aces

    return col;
}

fixed4 ShadowCasterfrag(v2f i) : SV_Target
{
    initUVs(i);
    half4 mainTex = MAIN_TEX(_MainTex, sampler_MainTex, uvs[_MainTexUV], _MainTex_ST);

    half alpha = mainTex.a * _Color.a;

    #ifdef ENABLE_TRANSPARENCY
        if(_Mode == 1) clip(alpha - _Cutoff);
        if(_Mode > 1) clip(alpha-0.5);
    #endif

    SHADOW_CASTER_FRAGMENT(i);
}

#endif