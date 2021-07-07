#ifndef VRS_FRAG
#define VRS_FRAG
fixed4 frag(v2f i) : SV_Target
{
    float4 mainTex = _MainTex.Sample(sampler_MainTex, i.uv);

    float intensity = dot(mainTex, grayscaleVec);
    mainTex.rgb = lerp(intensity, mainTex, (_Saturation+1));


    float4 albedo = mainTex * _Color;
    #ifdef ENABLE_VERTEXCOLOR
    UNITY_BRANCH
    if(_EnableVertexColor){
        float3 vertexColor = GammaToLinearSpace(i.color);
        albedo.rgb *= vertexColor;
    }
    #endif
    
    #ifdef ENABLE_TRANSPARENCY
    float alpha = calcAlpha(_Cutoff,albedo.a,_Mode);
    #else
    float alpha = 1;
    #endif
    
    #if defined(UNITY_PASS_SHADOWCASTER)
        SHADOW_CASTER_FRAGMENT(i);
    #else

    float3 diffuse = albedo;

    
    #ifndef ENABLE_PACKED_MODE
    
    #ifdef ENABLE_METALLICMAP
    float4 metallicMap = _MetallicMap.Sample(sampler_MainTex, i.uv);
    #endif
    
    #ifdef ENABLE_ROUGHNESSMAP
    float roughnessMap = _RoughnessMap.Sample(sampler_MainTex, i.uv);
    #endif
    
    #ifdef ENABLE_OCCLUSIONMAP
    float occlusionMap = _OcclusionMap.Sample(sampler_MainTex, i.uv);
    #endif

    
    #else
    #define ENABLE_ROUGHNESSMAP
    #define ENABLE_OCCLUSIONMAP
    #define ENABLE_METALLICMAP
    float4 packedTex = _PackedTexture.Sample(sampler_MainTex, i.uv);
    float metallicMap = packedTex.r;
    float roughnessMap = packedTex.a;
    float occlusionMap = packedTex.g;
    #endif

    
    #ifdef ENABLE_ROUGHNESSMAP
    float perceptualRoughness = _Roughness * roughnessMap;
    #else
    float perceptualRoughness = _Roughness;
    #endif

    #ifdef ENABLE_METALLICMAP
    float metallic = metallicMap * _Metallic;
    float reflectance = metallicMap * _Reflectance;
    #else
    float reflectance = _Reflectance;
    float metallic = _Metallic;
    #endif
    
    #ifdef ENABLE_OCCLUSIONMAP
    float occlusion = lerp(1,occlusionMap , _OcclusionStrength);
    #endif

    float oneMinusMetallic =  1 - metallic;
    float roughness = perceptualRoughness*perceptualRoughness;
    
    albedo.rgb *= oneMinusMetallic;
    

    
    
    float3 worldNormal = normalize(i.worldNormal);
    
    #if defined(_GLOSSYREFLECTIONS_OFF) || defined(_SPECULARHIGHLIGHTS_OFF) || defined (ENABLE_NORMALMAP)
    float3 tangent = i.tangent;
    float3 bitangent = i.bitangent;
    #endif

    
    
    #ifdef ENABLE_GSAA
    perceptualRoughness = GSAA_Filament(worldNormal, perceptualRoughness);
    #endif


    #ifdef ENABLE_NORMALMAP
    #if !defined(OPTIMIZER_ENABLED)
    if(_EnableNormalMap==0) _BumpScale = 0;
    #endif
    
    float4 normalMap = _BumpMap.Sample(sampler_BumpMap, i.uv);
    initBumpedNormalTangentBitangent(normalMap, bitangent, tangent, worldNormal, _BumpScale); // broken
    #endif

    


    

    

    

    
    
    bool lightEnv = any(_WorldSpaceLightPos0.xyz);
    float3 indirectDominantColor = half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    float3 lightDir = getLightDir(lightEnv, i.worldPos);
  //  float3 lightCol = getLightCol(lightEnv, _LightColor0.rgb, indirectDominantColor);
    float3 lightCol = _LightColor0.rgb;
    
    float NoL = saturate(dot(worldNormal, lightDir));

    
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
    
    
    #ifdef UNITY_PASS_FORWARDBASE // fix for rare bug where light atten is 0 when there is no directional light in the scene
    if(all(_LightColor0.rgb == 0.0)) 
    {
        attenuation = 1;
    }
    #endif
    
    
    float3 indirectDiffuse = getIndirectDiffuse(worldNormal);
    

    

    float3 NtL = NoL * lightCol;

    float3 light = (NtL * attenuation);
    float3 directDiffuse = albedo;

    #if defined(LIGHTMAP_ON) // apply lightmap /// fuck

    float3 lightMap = getLightmap(i.uv1, worldNormal, i.worldPos);

        
        
    #if defined(DYNAMICLIGHTMAP_ON) // apply realtime lightmap // IDK
        float3 realtimeLightMap = getRealtimeLightmap(i.uv2, worldNormal);
        directDiffuse *= lightMap + realtimeLightMap + light; 

    
    #else
    directDiffuse *= lightMap + light ;
    #endif

    
    
    #else


    directDiffuse *= light + indirectDiffuse;
    #endif

    
    
   

    
float3 col = directDiffuse;
    


    

    
    #if defined(_GLOSSYREFLECTIONS_OFF) || defined(_SPECULARHIGHLIGHTS_OFF)
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    float NoV = abs(dot(worldNormal, viewDir)) + 1e-5;

    float3 halfVector = normalize(lightDir + viewDir);
    float LoH = saturate(dot(lightDir, halfVector));

    
    
    


    float3 f0 = 0.16 * reflectance * reflectance * oneMinusMetallic + diffuse * metallic;

    float3 fresnel = F_Schlick(f0, NoV);


   fresnel = lerp(fresnel, f0, metallic); // kill fresnel on metallics, it looks bad.


    

    

    
     #endif


    
        
    #ifdef _GLOSSYREFLECTIONS_OFF // reflections
    float3 worldPos = i.worldPos;
 //   float3 reflViewDir = getAnisotropicReflectionVector(viewDir, bitangent, tangent, worldNormal, perceptualRoughness, _Anisotropy);
    float3 reflViewDir = reflect(-viewDir, worldNormal);
    float3 indirectSpecular = getIndirectSpecular(metallic, perceptualRoughness, reflViewDir, worldPos, directDiffuse, worldNormal) * lerp(fresnel, f0, perceptualRoughness);




    #if defined(LIGHTMAP_ON)
    UNITY_BRANCH
    if(_SpecularOcclusion > 0){
            float specMultiplier = saturate(lerp(1, pow(length(lightMap), _SpecularOcclusion), _SpecularOcclusion));
            specMultiplier = lerp(specMultiplier,1,metallic);
            indirectSpecular *= specMultiplier;
    }
    #endif


col += indirectSpecular;
    #endif




    
    #ifdef _SPECULARHIGHLIGHTS_OFF // specular highlights
    
    float NoH = saturate(dot(worldNormal, halfVector));

    float3 directSpecular = getDirectSpecular(perceptualRoughness, NoH, NoV, NoL, LoH, f0) * attenuation * NtL;

    


    
col += directSpecular;
    #endif
    




    #ifdef ENABLE_OCCLUSIONMAP
col*= occlusion;
    #endif

#ifdef ENABLE_EMISSION
UNITY_BRANCH
if(_EnableEmission==1)
    col += _EmissionMap.Sample(sampler_MainTex, i.uv) * _EmissionColor;
#endif


    return float4(col , alpha);
    


    #endif
}
#endif