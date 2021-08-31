#ifndef LITFRAG
#define LITFRAG

half4 frag(v2f i) : SV_Target
{

    UNITY_SETUP_INSTANCE_ID(i); 

    uvs[0] = i.texcoord0.xy;
    uvs[1] = i.texcoord0.zw;
    uvs[2] = i.texcoord1.xy;

    half4 mainTex = _MainTex.Sample(sampler_MainTex, TRANSFORM(uvs[_MainTexUV].xy, _MainTex_ST));

    
    
    //half4 mainTex = sampleTex(_MainTex, 1, _MainTexUV, i.worldPos, i.worldNormal);
    half intensity = dot(mainTex, grayscaleVec); // saturation
    mainTex.rgb = lerp(intensity, mainTex.rgb, (_Saturation+1));


    half4 albedo = mainTex * _Color;

    half4 vertexColor = 1;
    #ifdef ENABLE_VERTEXCOLOR
    vertexColor = i.color;
    albedo.rgb *= _EnableVertexColor ? GammaToLinearSpace(vertexColor) : 1;
    #endif
    
    
    half alpha = 1;
    #ifdef ENABLE_TRANSPARENCY
    alpha = calcAlpha(_Cutoff,albedo.a);
    if(_Mode!=1 && _Mode!=0) albedo.rgb *= _Color.a;

    #endif

    
    

    half isRoughness = _GlossinessInvert;
    half4 maskMap = 1;
    half4 detailMap = 1;
    half metallicMap = 1;
    half smoothnessMap = 1;
    half occlusionMap = 1;

    #ifndef ENABLE_PACKED_MODE
    #ifdef PROP_METALLICMAP
    metallicMap = _MetallicMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_MetallicMapUV], _MetallicMap_ST, _MainTex_ST));
    #endif
    #ifdef PROP_SMOOTHNESSMAP
    smoothnessMap = _SmoothnessMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_SmoothnessMapUV], _SmoothnessMap_ST, _MainTex_ST));
    #endif
    #ifdef PROP_OCCLUSIONMAP
    occlusionMap = _OcclusionMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_OcclusionMapUV], _OcclusionMap_ST, _MainTex_ST));
    #endif

    #else

    #ifdef PROP_METALLICGLOSSMAP
    #define PROP_SMOOTHNESSMAP
    #define PROP_OCCLUSIONMAP
    #define PROP_METALLICMAP
    maskMap = _MetallicGlossMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_MetallicGlossMapUV], _MetallicGlossMap_ST, _MainTex_ST));
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
    albedo.rgb = ( albedo.rgb * maskMap.bbb ) + BlendMode_Overlay(albedo.rgb, detailMap.rrr);
    
    #endif
*/
    half3 diffuse = albedo.rgb;
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
    half4 normalMap = _BumpMap.Sample(sampler_BumpMap, TRANSFORMTEX(uvs[_BumpMapUV], _BumpMap_ST, _MainTex_ST));
    #if defined(PROP_DETAILMAP) && defined(PROP_METALLICGLOSSMAP)
      
    #endif
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
    if(all(_LightColor0.rgb == 0.0)) attenuation = 1;
    #endif
    
    
    
    

    half3 light = (NoL * attenuation * lightCol);
    half3 directDiffuse = albedo;

    
    
    #ifndef SHADER_API_MOBILE
    light *= Fd_Burley(perceptualRoughness, NoV, NoL, LoH);
    #endif
    
    half3 indirectDiffuse = 0;
    #if defined(LIGHTMAP_ON)
    half3 lightMap = getLightmap(uvs[1], worldNormal);
    
    #if defined(DYNAMICLIGHTMAP_ON)
    half3 realtimeLightMap = getRealtimeLightmap(uvs[2], worldNormal);
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

    //#if defined(LIGHTMAP_ON)
        fresnel *= _SpecularOcclusion ? saturate(lerp(1, pow(length(indirectDiffuse), _SpecularOcclusion), _SpecularOcclusion * (1 - metallic))) : 1; // lightmap occlusion
    //#endif

    #if !defined(SHADER_API_MOBILE)
        #if defined(ENABLE_GSAA)
            perceptualRoughness = GSAA_Filament(worldNormal, perceptualRoughness);
        #endif
    #endif

#endif


// reflections
half3 indirectSpecular = 0;
#if defined(UNITY_PASS_FORWARDBASE)

    #if defined(ENABLE_REFLECTIONS)
        half3 reflViewDir = reflect(-viewDir, worldNormal);
        if(_Anisotropy != 0) reflViewDir = getAnisotropicReflectionVector(viewDir, bitangent, tangent, worldNormal, perceptualRoughness, _Anisotropy);
        indirectSpecular = getIndirectSpecular(metallic, perceptualRoughness, reflViewDir, i.worldPos, directDiffuse, worldNormal);
        indirectSpecular *= lerp(fresnel, f0, perceptualRoughness);
        //indirectSpecular *= f0;
    #endif

    #if defined(ENABLE_MATCAP)
        indirectSpecular = lerp(indirectSpecular, _MatCap.Sample(sampler_MainTex, mul((float3x3)UNITY_MATRIX_V, worldNormal).xy * 0.5 + 0.5).rgb, _MatCapReplace);
    #endif

    #if defined(PROP_OCCLUSIONMAP)
        indirectSpecular *= computeSpecularAO(NoV, occlusion, perceptualRoughness * perceptualRoughness);
    #endif

#endif
// reflections


// specular highlights
half3 directSpecular = 0;
#ifdef ENABLE_SPECULAR_HIGHLIGHTS
float NoH = saturate(dot(worldNormal, halfVector));
directSpecular = getDirectSpecular(perceptualRoughness, NoH, NoV, NoL, fresnel, _Anisotropy, halfVector, tangent, bitangent) * light;
#endif
// specular highlights


// emission
half3 emissionMap = 1;
half3 emission = 0;
#if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_META)
#if defined(PROP_EMISSIONMAP)
emissionMap = _EmissionMap.Sample(sampler_MainTex, TRANSFORMTEX(uvs[_EmissionMapUV], _EmissionMap_ST, _MainTex_ST)).rgb;
#endif


emission = _EnableEmission ? emissionMap * pow(_EmissionColor.rgb, 2.2) : 0;
#endif
// emission


// final color
half3 finalColor = directDiffuse * ((indirectDiffuse * occlusion) + light) + directSpecular + indirectSpecular + emission;


#ifdef UNITY_PASS_META
    UnityMetaInput surfaceData;
    UNITY_INITIALIZE_OUTPUT(UnityMetaInput, surfaceData);
    surfaceData.Emission = emission;
    surfaceData.Albedo = albedo;
    surfaceData.SpecularColor = indirectSpecular;
    return UnityMetaFragment(surfaceData);
#endif

finalColor = _TonemappingMode ? lerp(finalColor, ACESFilm(finalColor), _Contribution) : finalColor; // aces

alpha -= mainTex.a * 0.00001; // fix main tex sampler without changing the color;


    return half4(finalColor, alpha);

}

fixed4 ShadowCasterfrag(v2f i) : SV_Target
{

    uvs[0] = i.texcoord0.xy;
    uvs[1] = i.texcoord0.zw;
    uvs[2] = i.texcoord1.xy;

    half4 mainTex = _MainTex.Sample(sampler_MainTex, TRANSFORM(uvs[_MainTexUV], _MainTex_ST));

    half alpha = mainTex.a * _Color.a;

    #ifdef ENABLE_TRANSPARENCY
    alpha = calcAlpha(_Cutoff,alpha);
    if(_Mode > 1) clip(alpha-0.5);
    #endif
    SHADOW_CASTER_FRAGMENT(i);
}

#endif