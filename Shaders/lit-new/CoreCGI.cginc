float4 frag (v2f i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    float2 parallaxOffset = 0;
    float3 emission = 0;
    float3 indirectSpecular = 0;
    float3 directSpecular = 0;
    float3 vertexLight = 0;
    float3 indirectDiffuse = 1;

    float2 textureUV = i.coord0.xy + parallaxOffset;
    

    float4 mainTexture = SAMPLE_TEX2D(_MainTex, textureUV) * _Color;
    float alpha = mainTexture.a;

    #if defined(UNITY_PASS_SHADOWCASTER)
        SHADOW_CASTER_FRAGMENT(i);
    #endif



    #if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)

        float4 albedo = mainTexture;

        float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
        float3 worldNormal = normalize(i.worldNormal);
        float NoV = abs(dot(worldNormal, viewDir)) + 1e-5;


        float occlusionMap = 1;
        float metallicMap = 1;
        float smothnessMap = 1;
        float detailMask = 1;

        #ifdef MASKMAP
            float4 maskMap = SAMPLE_TEX2D_SAMPLER(_MetallicGlossMap, sampler_MainTex, textureUV);
            metallicMap = maskMap.r;
            detailMask = maskMap.b;
            occlusionMap = maskMap.g;
            smothnessMap = maskMap.a;
        #endif

        float perceptualRoughness = 1 - (_Glossiness * smothnessMap);
        float metallic = _Metallic * metallicMap;
        float oneMinusMetallic = 1 - metallic;
        float occlusion = lerp(1, occlusionMap, _Occlusion);
        
        

        
        // tangent bitangent
        #if defined(NEEDS_TANGENT_BITANGENT)
            float3 tangent = i.tangent;
            float3 bitangent = i.bitangent;

            #if defined(NORMALMAP)
                float4 normalMap = SAMPLE_TEX2D(_BumpMap, textureUV);
            #else
                float4 normalMap = float4(0.5, 0.5, 0.5, 1);
                _BumpScale = 0;
            #endif
            float3 tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);
            tangentNormal.g *= -1;

            half3 calcedNormal = normalize
            (
                tangentNormal.x * tangent +
                tangentNormal.y * bitangent +
                tangentNormal.z * worldNormal
            );

            worldNormal = calcedNormal;
            tangent = normalize(cross(worldNormal, bitangent));
            bitangent = normalize(cross(worldNormal, tangent));
        #endif

        #if defined(GEOMETRIC_SPECULAR_AA)
            perceptualRoughness = GSAA_Filament(worldNormal, perceptualRoughness);
        #endif
        

        // realtime light
        float3 lightDirection = Unity_SafeNormalize(UnityWorldSpaceLightDir(i.worldPos));
        float3 lightHalfVector = Unity_SafeNormalize(lightDirection + viewDir);
        float lightNoL = saturate(dot(worldNormal, lightDirection));
        float lightLoH = saturate(dot(lightDirection, lightHalfVector));
        LIGHT_ATTENUATION_NO_SHADOW_MUL(attenuationNoShadow, i, i.worldPos.xyz);
        float lightAttenuation = attenuationNoShadow * shadow;
        float3 lightFinal = (lightNoL * lightAttenuation * _LightColor0.rgb) * Fd_Burley(perceptualRoughness, NoV, lightNoL, lightLoH);
        

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


        
        float3 f0 = 0.16 * _Reflectance * _Reflectance * oneMinusMetallic + albedo * metallic;
        float3 fresnel = lerp(f0, F_Schlick(NoV, f0) , _FresnelColor.a) * _FresnelColor.rgb;
 
        // fresnel *= _SpecularOcclusion ? saturate(lerp(1, pow(length(light.indirectDiffuse), _SpecularOcclusionSensitivity), _SpecularOcclusion)) * surface.oneMinusMetallic : 1;
        
        #if defined(UNITY_PASS_FORWARDBASE)
            #if defined(REFLECTIONS)
                float3 reflDir = reflect(-viewDir, worldNormal);
                // if(_EnableAnisotropy) reflViewDir = getAnisotropicReflectionVector(viewDir, bitangent, tangent, worldNormal, perceptualRoughness);
                Unity_GlossyEnvironmentData envData;
                envData.roughness = perceptualRoughness;
                envData.reflUVW = getBoxProjection(
                    reflDir, i.worldPos,
                    unity_SpecCube0_ProbePosition,
                    unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
                );

                half3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
                indirectSpecular = probe0;

                #if defined(UNITY_SPECCUBE_BLENDING)
                    half interpolator = unity_SpecCube0_BoxMin.w;
                    UNITY_BRANCH
                    if (interpolator < 0.99999)
                    {
                        envData.reflUVW = getBoxProjection(
                            reflDir, i.worldPos,
                            unity_SpecCube1_ProbePosition,
                            unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
                        );
                        half3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube1_HDR, envData);
                        indirectSpecular = lerp(probe1, probe0, interpolator);
                    }
                #endif
                half horizon = min(1 + dot(reflDir, worldNormal), 1);
                indirectSpecular = indirectSpecular * lerp(fresnel, f0, perceptualRoughness) * horizon * horizon;
            #endif

            #if defined(REFLECTIONS)
                indirectSpecular *= computeSpecularAO(NoV, occlusion, perceptualRoughness * perceptualRoughness);
            #endif
        #endif

        #ifdef SPECULAR_HIGHLIGHTS
            half NoH = saturate(dot(worldNormal, lightHalfVector));
            half roughness = max(perceptualRoughness * perceptualRoughness, 0.002);

            float F = F_Schlick(lightLoH, f0);
            float D = GGXTerm (NoH, roughness);
            float V = V_SmithGGXCorrelated (NoV, lightNoL, roughness);

            directSpecular += max(0, (D * V) * F) * lightFinal * UNITY_PI;
        #endif
        

        float4 finalColor = float4( albedo * oneMinusMetallic * (indirectDiffuse * occlusion + (lightFinal + vertexLight)) + indirectSpecular + directSpecular + emission, alpha);
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
        return finalColor;

    #endif
    
}