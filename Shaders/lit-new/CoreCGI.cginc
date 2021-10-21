float4 frag (v2f i, bool facing : SV_IsFrontFace) : SV_Target
{
    input = i;
    
    float4 mainTexture = SampleTexture(_MainTex, _MainTex_ST, sampler_MainTex, _MainTex_UV) * _Color;

#if defined(UNITY_PASS_SHADOWCASTER)
    SHADOW_CASTER_FRAGMENT(i);
#else

    float alpha = 1;
    float3 emission = 0;
    float perceptualRoughness = 0;
    float metallic = 0;
    float occlusion = 1;
    float3 indirectDiffuse = 1;
    float3 pixelLight = 0;
    float3 vertexLight = 0;
    float3 indirectSpecular = 0;
    float3 directSpecular = 0;
    float2 lightmapUV = 0;

    float3 worldNormal = normalize(i.worldNormal);
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

        lightmapUV = i.coord0.zw * unity_LightmapST.xy + unity_LightmapST.zw;
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








    
    alpha -= mainTexture.a * 0.00001;

    float4 finalColor = float4(mainTexture.rgb * (1 - metallic) * (indirectDiffuse * occlusion + (pixelLight + vertexLight)) + indirectSpecular + directSpecular + emission, alpha);

    #ifdef FOG
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
    #endif

    return finalColor;
#endif
}