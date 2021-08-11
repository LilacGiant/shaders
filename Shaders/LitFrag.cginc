#ifndef LITFRAG
#define LITFRAG

half4 frag(v2f i) : SV_Target
{

    uvs[0] = i.uv0;
    uvs[1] = i.uv1;
    uvs[2] = i.uv2;


    half4 mainTex = _MainTex.Sample(sampler_MainTex, TRANSFORM_TEX(uvs[_MainTexUV], _MainTex));

    half intensity = dot(mainTex, grayscaleVec); // saturation
    mainTex.rgb = lerp(intensity, mainTex, (_Saturation+1));


    half4 albedo = mainTex * _Color; // unity please give me my main tex sampler

    half4 vertexColor = 1;
    #ifdef ENABLE_VERTEXCOLOR
    vertexColor = i.color;
    albedo.rgb *= _EnableVertexColor ? GammaToLinearSpace(vertexColor) : 1;
    #endif
    
    
    half alpha = 1;
    #ifdef ENABLE_TRANSPARENCY
    alpha = calcAlpha(_Cutoff,albedo.a,_Mode);
    if(_Mode!=1 && _Mode!=0) albedo.rgb *= _Color.a;

    #endif

    half3 diffuse = albedo.rgb;
    

    half isRoughness = _GlossinessInvert;
    half4 maskMap = 1;
    half metallicMap = 1;
    half smoothnessMap = 1;
    half occlusionMap = 1;
    half detailMap = 1;

    #ifndef ENABLE_PACKED_MODE
    #ifdef PROP_METALLICMAP
    metallicMap = _MetallicMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_MetallicMapUV], _MetallicMap));
    #endif
    #ifdef PROP_SMOOTHNESSMAP
    smoothnessMap = _SmoothnessMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_SmoothnessMapUV], _SmoothnessMap));
    #endif
    #ifdef PROP_OCCLUSIONMAP
    occlusionMap = _OcclusionMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_OcclusionMapUV], _OcclusionMap));
    #endif

    #else

    #ifdef PROP_METALLICGLOSSMAP
    #define PROP_SMOOTHNESSMAP
    #define PROP_OCCLUSIONMAP
    #define PROP_METALLICMAP
    maskMap = _MetallicGlossMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_MetallicGlossMapUV], _MetallicGlossMap));
    #endif
    metallicMap = maskMap.r;
    smoothnessMap = maskMap.a;
    occlusionMap = maskMap.g;
    isRoughness = 0;
    #endif


    half smoothness = _Glossiness * smoothnessMap;
    half perceptualRoughness = isRoughness ? smoothness : 1-smoothness;
    half metallic = metallicMap * _Metallic;
    half occlusion = lerp(1,occlusionMap , _Occlusion);

    
    albedo.rgb *= 1 - metallic;

    if(_EnableVertexColorMask) {
        metallic *= vertexColor.r;
        perceptualRoughness *= vertexColor.a;
        occlusion *= vertexColor.g;
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
    half4 normalMap = _BumpMap.Sample(sampler_BumpMap, TRANSFORM_MAINTEX(uvs[_BumpMapUV], _BumpMap));
    initBumpedNormalTangentBitangent(normalMap, bitangent, tangent, worldNormal, _BumpScale, _NormalMapOrientation);
    #endif


    


    

    

    

    half3 indirectDominantColor = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    half3 lightDir = getLightDir(!_GetDominantLight, i.worldPos);
    half3 lightCol = getLightCol(!_GetDominantLight, _LightColor0.rgb, indirectDominantColor);

    half NoL = saturate(dot(worldNormal, lightDir));
    half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    float NoV = abs(dot(worldNormal, viewDir)) + 1e-5;
    half3 halfVector = normalize(lightDir + viewDir);
    float LoH = saturate(dot(lightDir, halfVector));
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);


    
    
    
    
    #ifdef UNITY_PASS_FORWARDBASE // fix for rare bug where light atten is 0 when there is no directional light in the scene
    if(all(_LightColor0.rgb == 0.0)) 
    {
        attenuation = 1;
    }
    #endif
    
    
    
    

    half3 light = (NoL * attenuation * lightCol);
    half3 directDiffuse = albedo;

    
    
    #ifndef SHADER_API_MOBILE
    light *= Fd_Burley(perceptualRoughness, NoV, NoL, LoH);
    #endif
    
    half3 indirectDiffuse = 0;
    #if defined(LIGHTMAP_ON)
    half3 lightMap = getLightmap(uvs[1], worldNormal, i.worldPos);
    
    #if defined(DYNAMICLIGHTMAP_ON)
    half3 realtimeLightMap = getRealtimeLightmap(uvs[1], worldNormal);
    lightMap +=realtimeLightMap; 
    #endif
    
    indirectDiffuse = lightMap;
    
    #else

    indirectDiffuse = getIndirectDiffuse(worldNormal);

    #endif

 


    





#if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS)

    half3 f0 = 0.16 * _Reflectance * _Reflectance * (1 - metallic) + diffuse * metallic;
    half3 fresnel = F_Schlick(f0, NoV);
    fresnel = lerp(f0, fresnel , _FresnelColor.a); // kill fresnel
    fresnel *= _FresnelColor.rgb;

    #if defined(LIGHTMAP_ON)
        fresnel *= _SpecularOcclusion ? saturate(lerp(1, pow(length(lightMap), _SpecularOcclusion), _SpecularOcclusion)) : 1; // lightmap occlusion
    #endif

    #if !defined(SHADER_API_MOBILE)
        perceptualRoughness = _AngularGlossiness ? lerp(saturate(perceptualRoughness * (1-_AngularGlossiness * fresnel)), perceptualRoughness,  perceptualRoughness) : perceptualRoughness;  // roughness fresnel
        #if defined(ENABLE_GSAA)
            perceptualRoughness = GSAA_Filament(worldNormal, perceptualRoughness);
        #endif
    #endif

#endif


// reflections
half3 indirectSpecular = 0;
#ifdef ENABLE_REFLECTIONS 
float3 worldPos = i.worldPos;
half3 reflViewDir = reflect(-viewDir, worldNormal);
indirectSpecular = getIndirectSpecular(metallic, perceptualRoughness, reflViewDir, worldPos, directDiffuse, worldNormal) * lerp(fresnel, f0, perceptualRoughness);
#ifdef PROP_OCCLUSIONMAP
indirectSpecular *= computeSpecularAO(NoV, occlusion, perceptualRoughness * perceptualRoughness);
#endif
#endif
// reflections


// specular highlights
half3 directSpecular = 0;
#ifdef ENABLE_SPECULAR_HIGHLIGHTS
float NoH = saturate(dot(worldNormal, halfVector));
directSpecular = getDirectSpecular(perceptualRoughness, NoH, NoV, NoL, LoH, f0) * light;
#endif
// specular highlights


// emission
half3 emissionMap = 1;
#if defined(PROP_EMISSIONMAP)
emissionMap = _EmissionMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_EmissionMapUV], _EmissionMap)).rgb;
#endif
half3 emission = _EnableEmission ? emissionMap * _EmissionColor.rgb * attenuation : 0;
// emission


// final color
half3 finalColor = directDiffuse * ((indirectDiffuse * occlusion) + light) + directSpecular + indirectSpecular + emission;

finalColor.rgb = _TonemappingMode ? lerp(finalColor.rgb, ACESFilm(finalColor.rgb), _Contribution) : finalColor.rgb; // aces

alpha += mainTex.a * 0.00001; // fix main tex sampler without changing the color;

    return half4(finalColor, alpha);

}

fixed4 ShadowCasterfrag(v2f i) : SV_Target
{
    uvs[0] = i.uv0;
    uvs[1] = i.uv1;
    uvs[2] = i.uv2;
    half4 mainTex = _MainTex.Sample(sampler_MainTex, TRANSFORM_TEX(uvs[_MainTexUV], _MainTex));

    half alpha = mainTex.a * _Color.a;

    #ifdef ENABLE_TRANSPARENCY
    alpha = calcAlpha(_Cutoff,alpha,_Mode);
    if(_Mode > 1) clip(alpha-0.5);
    #endif
    SHADOW_CASTER_FRAGMENT(i);
}

#endif