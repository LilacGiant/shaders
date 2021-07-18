#ifndef LITFRAG
#define LITFRAG
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11

half4 frag(v2f i) : SV_Target
{
    uvs[0] = i.uv0;
    uvs[1] = i.uv1;
    uvs[2] = i.uv2;

    half4 mainTex = _MainTex.Sample(sampler_MainTex, TRANSFORM_TEX(uvs[_MainTexUV], _MainTex));

    half intensity = dot(mainTex, grayscaleVec);
    mainTex.rgb = lerp(intensity, mainTex, (_Saturation+1));

    half4 albedo = mainTex * _Color;

    #ifdef ENABLE_VERTEXCOLOR
    UNITY_BRANCH
    if(_EnableVertexColor){
        half3 vertexColor = GammaToLinearSpace(i.color);
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
    

    
    #ifndef ENABLE_PACKED_MODE
    
    #ifdef ENABLE_METALLICMAP
    half4 metallicMap = _MetallicMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_MetallicMapUV], _MetallicMap));
    #endif
    
    #ifdef ENABLE_ROUGHNESSMAP
    half roughnessMap = _RoughnessMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_RoughnessMapUV], _RoughnessMap));
    #endif
    
    #ifdef ENABLE_OCCLUSIONMAP
    half occlusionMap = _OcclusionMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_OcclusionMapUV], _OcclusionMap));
    #endif

    
    #else
    #define ENABLE_ROUGHNESSMAP
    #define ENABLE_OCCLUSIONMAP
    #define ENABLE_METALLICMAP
    half4 packedTex = _PackedTexture.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_PackedTextureUV], _PackedTexture));
    half metallicMap = packedTex.r;
    half roughnessMap = packedTex.a;
    half occlusionMap = packedTex.g;
    #endif

    half perceptualRoughness = _Roughness;
    #ifdef ENABLE_ROUGHNESSMAP
    perceptualRoughness *= roughnessMap;
    #endif
    UNITY_BRANCH
    if(_RoughnessInvert){
        perceptualRoughness = 1-perceptualRoughness;
    }

    #ifdef ENABLE_METALLICMAP
    half metallic = metallicMap * _Metallic;
    half reflectance = metallicMap * _Reflectance;
    #else
    half reflectance = _Reflectance;
    half metallic = _Metallic;
    #endif
    
    #ifdef ENABLE_OCCLUSIONMAP
    half occlusion = lerp(1,occlusionMap , _OcclusionStrength);
    #endif

    half oneMinusMetallic =  1 - metallic;
    half roughness = perceptualRoughness*perceptualRoughness;
    
    albedo.rgb *= oneMinusMetallic;
    

    
    
    half3 worldNormal = normalize(i.worldNormal);
    
    #if defined(_GLOSSYREFLECTIONS_OFF) || defined(_SPECULARHIGHLIGHTS_OFF) || defined (ENABLE_NORMALMAP)
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

#ifdef ENABLE_GSAA
perceptualRoughness = GSAA_Filament(worldNormal, perceptualRoughness);
#endif
    


    

    

    

    
    
    bool lightEnv = any(_WorldSpaceLightPos0.xyz);
    half3 indirectDominantColor = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    half3 lightDir = getLightDir(lightEnv, i.worldPos);
  //  half3 lightCol = getLightCol(lightEnv, _LightColor0.rgb, indirectDominantColor);
    half3 lightCol = _LightColor0.xyz;
    
    float NoL = saturate(dot(worldNormal, lightDir));

    
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
    
    
    #ifdef UNITY_PASS_FORWARDBASE // fix for rare bug where light atten is 0 when there is no directional light in the scene
    if(all(_LightColor0.rgb == 0.0)) 
    {
        attenuation = 1;
    }
    #endif
    
    
    half3 indirectDiffuse = getIndirectDiffuse(worldNormal);
    


    half3 light = (NoL * attenuation * lightCol);
    half3 directDiffuse = albedo;

    #if defined(LIGHTMAP_ON) // apply lightmap /// fuck

    half3 lightMap = getLightmap(uvs[1], worldNormal, i.worldPos);

        
        
    #if defined(DYNAMICLIGHTMAP_ON) // apply realtime lightmap // IDK
        half3 realtimeLightMap = getRealtimeLightmap(uvs[1], worldNormal);
        directDiffuse *= lightMap + realtimeLightMap + light; 

    
    #else
    directDiffuse *= lightMap + light;
    #endif

    
    
    #else


    directDiffuse *= light + indirectDiffuse;
    #endif

    
    
   

    
half3 col = directDiffuse;
    


    
half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
float NoV = abs(dot(worldNormal, viewDir)) + 1e-5;


#if defined(_GLOSSYREFLECTIONS_OFF) || defined(_SPECULARHIGHLIGHTS_OFF)
half3 halfVector = normalize(lightDir + viewDir);
float LoH = saturate(dot(lightDir, halfVector));
half3 f0 = 0.16 * reflectance * reflectance * oneMinusMetallic + diffuse * metallic;
half3 fresnel = F_Schlick(f0, NoV);
fresnel = lerp(fresnel, f0, metallic); // kill fresnel on metallics, it looks bad.
#endif


        
#ifdef _GLOSSYREFLECTIONS_OFF // reflections
float3 worldPos = i.worldPos;
half3 reflViewDir = reflect(-viewDir, worldNormal);
half3 indirectSpecular = getIndirectSpecular(metallic, perceptualRoughness, reflViewDir, worldPos, directDiffuse, worldNormal) * lerp(fresnel, f0, perceptualRoughness);

#if defined(LIGHTMAP_ON)
UNITY_BRANCH
if(_SpecularOcclusion > 0){
    half specMultiplier = saturate(lerp(1, pow(length(lightMap), _SpecularOcclusion), _SpecularOcclusion));
    specMultiplier = lerp(specMultiplier,1,metallic);
    indirectSpecular *= specMultiplier;
}
#endif

col += indirectSpecular;
#endif


    
#ifdef _SPECULARHIGHLIGHTS_OFF // specular highlights
float NoH = saturate(dot(worldNormal, halfVector));
half3 directSpecular = getDirectSpecular(perceptualRoughness, NoH, NoV, NoL, LoH, f0) * light;
col += directSpecular;
#endif



#ifdef ENABLE_OCCLUSIONMAP
col*= occlusion;
#endif



#ifdef ENABLE_EMISSION
UNITY_BRANCH
if(_EnableEmission==1)
    col += _EmissionMap.Sample(sampler_MainTex, TRANSFORM_MAINTEX(uvs[_EmissionMapUV], _EmissionMap)) * _EmissionColor;
#endif



if(_EnableIridescence==1){
    half3 iridescenceTex = _IridescenceMap.Sample(sampler_MainTex,  NoV);
    half3 noiseTex = _NoiseMap.Sample(sampler_MainTex, float4(i.uv0.xy,4,4));
col += iridescenceTex*_IridescenceIntensity*noiseTex.r;
}


return half4(col , alpha);
}

fixed4 ShadowCasterfrag(v2f i) : SV_Target
{
    half alpha = _MainTex.Sample(sampler_MainTex, i.uv0).a * _Color.a;

    #ifdef ENABLE_TRANSPARENCY
    alpha = calcAlpha(_Cutoff,alpha,_Mode);
    #endif
    
    SHADOW_CASTER_FRAGMENT(i);
}

#endif
