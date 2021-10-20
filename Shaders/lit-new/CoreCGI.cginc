float4 frag (v2f i, bool facing : SV_IsFrontFace) : SV_Target
{
    input = i;
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

    float4 mainTexture = SampleTexture(_MainTex, _MainTex_ST, sampler_MainTex, _MainTex_UV) * _Color;

#if defined(UNITY_PASS_SHADOWCASTER)
    SHADOW_CASTER_FRAGMENT(i);
#else


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

    

    float4 finalColor = float4(mainTexture.rgb * (1 - metallic) * (indirectDiffuse * occlusion + (pixelLight + vertexLight)) + indirectSpecular + directSpecular + emission, alpha);
    #ifdef FOG
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
    #endif
    return finalColor;
#endif
}