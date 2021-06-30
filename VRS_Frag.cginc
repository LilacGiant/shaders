#ifndef VRS_FRAG
#define VRS_FRAG
fixed4 frag(v2f i) : SV_Target
{
    
    #if defined(UNITY_PASS_SHADOWCASTER)
        SHADOW_CASTER_FRAGMENT(i);
    #else

    float4 albedo = _MainTex.Sample(sampler_MainTex, i.uv) * _Color;
    float4 diffuse = albedo;

    


    #if defined(PROP_ENABLEMETALLICMAP) || !defined(OPTIMIZER_ENABLED) // metalic map
    float4 metallicMap = _MetallicMap.Sample(sampler_MainTex, i.uv);
    float metallic = metallicMap * _Metallic;
    float reflectance = metallicMap * _Reflectance;
    #else
    float reflectance = _Reflectance;
    float metallic = _Metallic;
    #endif

    float oneMinusMetallic =  1 - metallic;
    albedo.rgb *= oneMinusMetallic;


    #if defined(PROP_ENABLEROUGHNESSMAP) || !defined(OPTIMIZER_ENABLED) // roughness map
    float4 roughnessMap = _RoughnessMap.Sample(sampler_MainTex, i.uv);
    float perceptualRoughness = _Roughness * roughnessMap;
    #else
    float perceptualRoughness = _Roughness;
    #endif

    float roughness = perceptualRoughness*perceptualRoughness;


    
    float3 worldNormal = normalize(i.worldNormal);
    
    #if defined(_GLOSSYREFLECTIONS_OFF) || defined(_SPECULARHIGHLIGHTS_OFF) || defined (_NORMALMAP)
    float3 tangent = i.tangent;
    float3 bitangent = i.bitangent;
    #endif

    
    #ifdef UNITY_UI_CLIP_RECT // geometric specular antialiasing
    perceptualRoughness = GSAA_Filament(worldNormal, perceptualRoughness);
    #endif


    #ifdef _NORMALMAP // normal map
    float4 normalMap = _BumpMap.Sample(sampler_MainTex, i.uv);
    initBumpedNormalTangentBitangent(normalMap, bitangent, tangent, worldNormal, _BumpScale);
    #endif

    


    

    #if defined(PROP_ENABLEOCCLUSION) || !defined(OPTIMIZER_ENABLED) // occlusion
    float4 occlusionMap = _OcclusionMap.Sample(sampler_MainTex, i.uv);
    float occlusion = lerp(1,occlusionMap.g , _OcclusionStrength);
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
    #if defined(_DETAIL_MULX2)
    NtL *= occlusion;
    #endif
    float3 light = (NtL * attenuation);
    float3 directDiffuse = albedo;

    #if defined(LIGHTMAP_ON) // apply lightmap /// fuck
		float3 lightMap = getLightmap(i.uv1, worldNormal, i.worldPos);
        
        
    #if defined(DYNAMICLIGHTMAP_ON) // apply realtime lightmap
        float3 realtimeLightMap = getRealtimeLightmap(i.uv2, worldNormal);
        directDiffuse *= lightMap + realtimeLightMap; 

    
    #else
    directDiffuse *= lightMap;
    directDiffuse += light;
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

    #if defined(_DETAIL_MULX2)
   indirectSpecular *= computeSpecularAO(NoV,occlusion,roughness);
    #endif



col += indirectSpecular;
    #endif




    
    #ifdef _SPECULARHIGHLIGHTS_OFF // specular highlights
    
    float NoH = saturate(dot(worldNormal, halfVector));

    float3 directSpecular = getDirectSpecular(perceptualRoughness, NoH, NoV, NoL, LoH, f0) * attenuation * NtL;

    
    
col += directSpecular;
    #endif
    









    return float4(col , 1);
    


    #endif
}
#endif