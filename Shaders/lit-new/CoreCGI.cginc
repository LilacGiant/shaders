float4 frag (v2f i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    float2 parallaxOffset = 0;
    float3 emission = 0;
    float3 indirectSpecular = 0;
    float3 directSpecular = 0;
    float3 vertexLight = 0;
    float3 indirectDiffuse = 1;
    

    float4 mainTexture = _MainTex.Sample(sampler_MainTex, i.coord0.xy + parallaxOffset) * _Color;
    float alpha = mainTexture.a;

    #if defined(UNITY_PASS_SHADOWCASTER)
        SHADOW_CASTER_FRAGMENT(i);
    #endif



    #if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)

        float4 albedo = mainTexture;

        float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
        float3 worldNormal = normalize(i.worldNormal);
        float NoV = abs(dot(worldNormal, viewDir)) + 1e-5;
        float perceptualRoughness = 1 - (_Glossiness);
        float oneMinusMetallic = 1 - (_Metallic * _Metallic);
        float occlusionMap = 1;
        float occlusion = lerp(1, occlusionMap, _Occlusion);
        

        // realtime light
        float3 lightDirection = Unity_SafeNormalize(UnityWorldSpaceLightDir(i.worldPos));
        float3 lightColor = _LightColor0.rgb;
        float3 lightHalfVector = Unity_SafeNormalize(lightDirection + viewDir);
        float lightNoL = saturate(dot(worldNormal, lightDirection));
        float lightLoH = saturate(dot(lightDirection, lightHalfVector));
        LIGHT_ATTENUATION_NO_SHADOW_MUL(attenuationNoShadow, i, i.worldPos.xyz);
        float lightAttenuation = attenuationNoShadow * shadow;
        float3 lightFinal = (lightNoL * lightAttenuation * lightColor) * Fd_Burley(perceptualRoughness, NoV, lightNoL, lightLoH);
        

        // indirect diffuse
        #if defined(LIGHTMAP_ON)

            float4 bakedColorTex = 0;
            float2 lightmapUV = i.coord0.zw * unity_LightmapST.xy + unity_LightmapST.zw + parallaxOffset;
            half3 lightMap = tex2DFastBicubicLightmap(lightmapUV, bakedColorTex);

            #if defined(DIRLIGHTMAP_COMBINED)
                float4 lightMapDir = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, lightmapUV);
                lightMap = DecodeDirectionalLightmap(lightMap, lightMapDir, worldNormal);
            #endif

            #if defined(DYNAMICLIGHTMAP_ON)

                float2 realtimeUV = i.coord1.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw + parallaxOffset;
                half4 bakedCol = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, realtimeUV);
                float3 realtimeLightmap = DecodeRealtimeLightmap(bakedCol);

                #ifdef DIRLIGHTMAP_COMBINED
                    half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, realtimeUV);
                    realtimeLightmap += DecodeDirectionalLightmap (realtimeLightmap, realtimeDirTex, worldNormal);
                #endif
                lightMap += realtimeLightMap; 
            #endif

            #if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
                lightFinal = 0;
                lightNoL = 0;
                lightDirection = float3(0,1,0);
                lightMap = SubtractMainLightWithRealtimeAttenuationFromLightmap (lightMap, light.attenuation, bakedColorTex, worldNormal);
            #endif
            indirectDiffuse = lightMap;

        #else
            indirectDiffuse = max(0, ShadeSH9(float4(worldNormal, 1)));
        #endif

        #if defined(LIGHTMAP_SHADOW_MIXING) && defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) && defined(LIGHTMAP_ON)
            light.finalLight *= UnityComputeForwardShadows(lightmapUV, i.worldPos, i.screenPos);
        #endif

        float4 finalColor = float4( albedo * oneMinusMetallic * (indirectDiffuse * occlusion + (lightFinal + vertexLight)) + indirectSpecular + directSpecular + emission, alpha);
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
        return finalColor;

    #endif
    
}