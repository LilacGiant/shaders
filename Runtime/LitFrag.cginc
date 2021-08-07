#ifndef LITFRAG
#define LITFRAG

half4 frag(v2f i) : SV_Target
{
    uvs[0] = i.uv0;
    uvs[1] = i.uv1;
    uvs[2] = i.uv2;


    half4 mainTex = _MainTex.Sample(sampler_MainTex, TRANSFORM_TEX(uvs[_MainTexUV], _MainTex));

    half intensity = dot(mainTex, grayscaleVec);
    mainTex.rgb = lerp(intensity, mainTex, (_Saturation+1));


    half4 albedo = mainTex * (_Color+0.000001); // unity please give me my main tex sampler


    #ifdef ENABLE_VERTEXCOLOR
    half3 vertexColor;
    UNITY_BRANCH
    if(_EnableVertexColor){
        vertexColor = GammaToLinearSpace(i.color);
        albedo.rgb *= vertexColor;
    }
    #endif
    
    half alpha = 1;
    #ifdef ENABLE_TRANSPARENCY
    alpha = calcAlpha(_Cutoff,albedo.a,_Mode);
    if(_Mode!=1 && _Mode!=0)
    {
        albedo.rgb *= _Color.a;
    }
    #endif
    
    
    half3 diffuse = albedo;
    

    half isRoughness = _GlossinessInvert;
    #ifndef ENABLE_PACKED_MODE
    
    #ifdef ENABLE_METALLICMAP
    half4 metallicMap = _MetallicMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_MetallicMapUV], _MetallicMap));
    #endif
    #ifdef ENABLE_SMOOTHNESSMAP
    half smoothnessMap = _SmoothnessMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_SmoothnessMapUV], _SmoothnessMap));
    #endif
    #ifdef ENABLE_OCCLUSIONMAP
    half occlusionMap = _OcclusionMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_OcclusionMapUV], _OcclusionMap));
    #endif

    #else
    #define ENABLE_SMOOTHNESSMAP
    #define ENABLE_OCCLUSIONMAP
    #define ENABLE_METALLICMAP
    half4 packedTex = _MetallicGlossMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_MetallicGlossMapUV], _MetallicGlossMap));
    half metallicMap = packedTex.r;
    half smoothnessMap = packedTex.a;
    half occlusionMap = packedTex.g;
    isRoughness = 0;
    #endif

    half perceptualRoughness = _Glossiness;
    #ifdef ENABLE_SMOOTHNESSMAP
    perceptualRoughness *= smoothnessMap;
    #endif

    UNITY_BRANCH
    if(!isRoughness){
        perceptualRoughness = 1-perceptualRoughness;
    }

    #ifdef ENABLE_METALLICMAP
    half metallic = metallicMap * _Metallic;
    #else
    half metallic = _Metallic;
    #endif
    
    
    #ifdef ENABLE_OCCLUSIONMAP
    half occlusion = lerp(1,occlusionMap , _Occlusion);
    #endif

    half reflectance = _Reflectance;
    half oneMinusMetallic =  1 - metallic;
    half roughness = perceptualRoughness*perceptualRoughness;
    
    albedo.rgb *= oneMinusMetallic;
    
    
    
    half3 worldNormal = i.worldNormal;
    #ifndef SHADER_API_MOBILE
    worldNormal = normalize(worldNormal);
    #endif
    #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (ENABLE_NORMALMAP)
    half3 tangent = i.tangent;
    half3 bitangent = i.bitangent;
    #endif


    #ifdef ENABLE_NORMALMAP
    #if !defined(OPTIMIZER_ENABLED)
    if(_EnableNormalMap==0) _BumpScale = 0;
    #endif
    
    half4 normalMap = _BumpMap.Sample(sampler_BumpMap, TRANSFORM_MAINTEX(uvs[_BumpMapUV], _BumpMap));
    initBumpedNormalTangentBitangent(normalMap, bitangent, tangent, worldNormal, _BumpScale, _NormalMapOrientation);
    #endif

#if defined(ENABLE_GSAA) && !defined(SHADER_API_MOBILE)
perceptualRoughness = GSAA_Filament(worldNormal, perceptualRoughness);
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
    
    
    half3 indirectDiffuse = getIndirectDiffuse(worldNormal);
    #ifdef ENABLE_OCCLUSIONMAP
    indirectDiffuse *= occlusion;
    #endif
    

    half3 light = (NoL * attenuation * lightCol);
    half3 directDiffuse = albedo;
    
    #ifndef SHADER_API_MOBILE
    light *= Fd_Burley(perceptualRoughness, NoV, NoL, LoH);
    #endif
    

    #if defined(LIGHTMAP_ON) // apply lightmap /// fuck

    half3 lightMap = getLightmap(uvs[1], worldNormal, i.worldPos);

        
        
    #if defined(DYNAMICLIGHTMAP_ON) // apply realtime lightmap // IDK
        half3 realtimeLightMap = getRealtimeLightmap(uvs[1], worldNormal);
        directDiffuse *= lightMap + realtimeLightMap + light; 

    
    #else
    directDiffuse *= lightMap + light;
    #endif

    
    
    #else


    directDiffuse *= light  + indirectDiffuse;
    #endif

 
half3 col = directDiffuse;

    






#if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS)
half3 f0 = 0.16 * reflectance * reflectance * oneMinusMetallic + diffuse * metallic;
half3 fresnel = F_Schlick(f0, NoV);

//fresnel *= saturate(length(indirectDiffuse) * 1.0/(_ExposureOcclusion)); // indirect diffuse occlusion

#if defined(LIGHTMAP_ON)
UNITY_BRANCH
if(_SpecularOcclusion > 0){
    half specMultiplier = saturate(lerp(1, pow(length(lightMap), _SpecularOcclusion), _SpecularOcclusion)); // lightmap occlusion
    fresnel *= specMultiplier;
}
#endif

fresnel *= _FresnelColor.rgb; //fresnel color
fresnel = lerp(f0, fresnel , _FresnelColor.a); // kill fresnel

perceptualRoughness = lerp(saturate(perceptualRoughness * (1-_AngularGlossiness * fresnel)), perceptualRoughness,  perceptualRoughness);  // roughness fresnel
#endif

        
#ifdef ENABLE_REFLECTIONS // reflections
float3 worldPos = i.worldPos;
half3 reflViewDir = reflect(-viewDir, worldNormal);
half3 indirectSpecular = getIndirectSpecular(metallic, perceptualRoughness, reflViewDir, worldPos, directDiffuse, worldNormal) * lerp(fresnel, f0, perceptualRoughness);
#ifdef ENABLE_OCCLUSIONMAP
indirectSpecular *= computeSpecularAO(NoV, occlusion, roughness);
#endif
col += indirectSpecular;
#endif


    
#ifdef ENABLE_SPECULAR_HIGHLIGHTS // specular highlights
float NoH = saturate(dot(worldNormal, halfVector));
half3 directSpecular = getDirectSpecular(perceptualRoughness, NoH, NoV, NoL, LoH, f0) * light;
col += directSpecular;
#endif



UNITY_BRANCH
if(_EnableEmission==1) col += _EmissionMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_EmissionMapUV], _EmissionMap)) * _EmissionColor.rgb;


UNITY_BRANCH
if(_TonemappingMode) col.rgb = lerp(col.rgb, ACESFilm(col.rgb), _Contribution);


return half4(col , alpha);
}

fixed4 ShadowCasterfrag(v2f i) : SV_Target
{
    half alpha = _MainTex.Sample(sampler_MainTex, i.uv0).a * _Color.a;

    #ifdef ENABLE_TRANSPARENCY
    alpha = calcAlpha(_Cutoff,alpha,_Mode);
    #endif
    //return alpha;
    SHADOW_CASTER_FRAGMENT(i);
}

#endif