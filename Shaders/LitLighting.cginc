#ifndef LITLIGHTING
#define LITLIGHTING
#define grayscaleVec float3(0.2125, 0.7154, 0.0721)

float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

float sq(float x) {
    return x * x;
}

float D_GGX(float NoH, float roughness) {
    float a = NoH * roughness;
    float k = roughness / (1.0 - NoH * NoH + a * a);
    return k * k * (1.0 / UNITY_PI);
}


float D_GGX_Anisotropic(float NoH, float3 h, float3 t, float3 b, float at, float ab)
{
    float ToH = dot(t, h);
    float BoH = dot(b, h);
    float a2 = at * ab;
    float3 v = float3(ab * ToH, at * BoH, a2 * NoH);
    float v2 = dot(v, v);
    float w2 = a2 / v2;
    return a2 * w2 * w2 * (1.0 / UNITY_PI);
}


float V_Kelemen(float LoH) {
    return 0.25 / (LoH * LoH);
}

float3 F_Schlick(const float3 f0, float f90, float VoH) {
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float3 F_Schlick(const float3 f0, float VoH) {
    float f = pow(1.0 - VoH, 5.0);
    return f + f0 * (1.0 - f);
}

float F_Schlick(float f0, float f90, float VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float Fd_Burley(float roughness, float NoV, float NoL, float LoH)
{
    // Burley 2012, "Physically-Based Shading at Disney"
    float f90 = 0.5 + 2.0 * roughness * LoH * LoH;
    float lightScatter = F_Schlick(1.0, f90, NoL);
    float viewScatter  = F_Schlick(1.0, f90, NoV);
    return lightScatter * viewScatter;
}

// Energy conserving wrap diffuse term, does *not* include the divide by pi
float Fd_Wrap(float NoL, float w) {
    return saturate((NoL + w) / sq(1.0 + w));
}

float V_SmithGGXCorrelated(float NoV, float NoL, float roughness) {
    float a2 = roughness * roughness;
    float GGXV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float GGXL = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / (GGXV + GGXL);
}

float V_SmithGGXCorrelatedFast(float NoV, float NoL, float roughness) {
    float a = roughness;
    float GGXV = NoL * (NoV * (1.0 - a) + a);
    float GGXL = NoV * (NoL * (1.0 - a) + a);
    return 0.5 / (GGXV + GGXL);
}

float Fd_Lambert()
{
    return 1.0 / UNITY_PI;
}

float shEvaluateDiffuseL1Geomerics_local(float L0, float3 L1, float3 n)
{
    // average energy
    float R0 = max(0, L0);
    
    // avg direction of incoming light
    float3 R1 = 0.5f * L1;
    
    // directional brightness
    float lenR1 = length(R1);
    
    // linear angle between normal and direction 0-1
    //float q = 0.5f * (1.0f + dot(R1 / lenR1, n));
    //float q = dot(R1 / lenR1, n) * 0.5 + 0.5;
    float q = dot(normalize(R1), n) * 0.5 + 0.5;
    q = saturate(q); // Thanks to ScruffyRuffles for the bug identity.
    
    // power for q
    // lerps from 1 (linear) to 3 (cubic) based on directionality
    float p = 1.0f + 2.0f * lenR1 / R0;
    
    // dynamic range constant
    // should vary between 4 (highly directional) and 0 (ambient)
    float a = (1.0f - lenR1 / R0) / (1.0f + lenR1 / R0);
    
    return R0 * (a + (1.0f - a) * (p + 1.0f) * pow(q, p));
}

float3 getIndirectDiffuse(float3 normal)
{
    float3 indirectDiffuse;
    UNITY_BRANCH
    if(_LightProbeMethod == 0)
    {
        indirectDiffuse = max(0, ShadeSH9(half4(normal, 1)));
    }
    else
    {
        float3 L0 = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
        indirectDiffuse.r = shEvaluateDiffuseL1Geomerics_local(L0.r, unity_SHAr.xyz, normal);
        indirectDiffuse.g = shEvaluateDiffuseL1Geomerics_local(L0.g, unity_SHAg.xyz, normal);
        indirectDiffuse.b = shEvaluateDiffuseL1Geomerics_local(L0.b, unity_SHAb.xyz, normal);
	indirectDiffuse = max(0, indirectDiffuse);
    }
    return indirectDiffuse;
}

float3 getBoxProjection (float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax)
{
#ifndef SHADER_API_MOBILE
     #if defined(UNITY_SPECCUBE_BOX_PROJECTION)
        if (cubemapPosition.w > 0) {
            float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
            float scalar = min(min(factors.x, factors.y), factors.z);
            direction = direction * scalar + (position - cubemapPosition);
        }
    #endif
#endif
    return direction;
}

float3 getIndirectSpecular(float metallic, float roughness, float3 reflDir, float3 worldPos, float3 lightmap, float3 normal)
{
    float3 spec = float3(0,0,0);
    #if defined(UNITY_PASS_FORWARDBASE)
        float3 indirectSpecular;
        Unity_GlossyEnvironmentData envData;
        envData.roughness = roughness;
        envData.reflUVW = getBoxProjection(
            reflDir, worldPos,
            unity_SpecCube0_ProbePosition,
            unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
        );

        float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);
        float interpolator = unity_SpecCube0_BoxMin.w;
        UNITY_BRANCH
        if (interpolator < 0.99999)
        {
            envData.reflUVW = getBoxProjection(
                reflDir, worldPos,
                unity_SpecCube1_ProbePosition,
                unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
            );
            float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube0_HDR, envData);
            indirectSpecular = lerp(probe1, probe0, interpolator);
        }
        else
        {
            indirectSpecular = probe0;
        }
        float horizon = min(1 + dot(reflDir, normal), 1);
        indirectSpecular *= horizon * horizon;

        spec = indirectSpecular;
        

    #endif
    return spec;
}

half3 getDirectSpecular(half perceptualRoughness, half NoH, half NoV, half NoL, half3 fresnel, half anisotropy, half3 halfVector, half3 tangent, half3 bitangent)
{
    half roughness = max(perceptualRoughness * perceptualRoughness, 0.002);


    half D = D_GGX(NoH, roughness);

    if(_Anisotropy != 0) {
        anisotropy *= saturate(5.0 * perceptualRoughness);
        half at = max(roughness * (1.0 + anisotropy), 0.001);
        half ab = max(roughness * (1.0 - anisotropy), 0.001);
        D = D_GGX_Anisotropic(NoH, halfVector, tangent, bitangent, at, ab);
    }
    #ifdef SHADER_API_MOBILE
    half V = V_SmithGGXCorrelatedFast(NoV, NoL, roughness);
    #else
    half V = V_SmithGGXCorrelated(NoV, NoL, roughness);
    #endif  
    half3 F = fresnel;
   
    half3 directSpecular = max(0, (D * V) * F);

    return directSpecular * UNITY_PI;
}


float3 getAnisotropicReflectionVector(float3 viewDir, float3 bitangent, float3 tangent, float3 normal, float roughness, float anisotropy)
{
    //_Anisotropy = lerp(-0.2, 0.2, sin(_Time.y / 20)); //This is pretty fun
    float3 anisotropicDirection = anisotropy >= 0.0 ? bitangent : tangent;
    float3 anisotropicTangent = cross(anisotropicDirection, viewDir);
    float3 anisotropicNormal = cross(anisotropicTangent, anisotropicDirection);
    float bendFactor = abs(anisotropy) * saturate(5.0 * roughness);
    float3 bentNormal = normalize(lerp(normal, anisotropicNormal, bendFactor));
    return reflect(-viewDir, bentNormal);
}

#ifdef DYNAMICLIGHTMAP_ON
float3 getRealtimeLightmap(float2 uv, float3 worldNormal)
{
    float2 realtimeUV = uv * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    half4 bakedCol = UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, realtimeUV);
    float3 realtimeLightmap = DecodeRealtimeLightmap(bakedCol);

    #ifdef DIRLIGHTMAP_COMBINED
        half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, realtimeUV);
        realtimeLightmap += DecodeDirectionalLightmap (realtimeLightmap, realtimeDirTex, worldNormal);
    #endif

    return realtimeLightmap;
}
#endif


// w0, w1, w2, and w3 are the four cubic B-spline basis functions
float w0(float a)
{
    //    return (1.0f/6.0f)*(-a*a*a + 3.0f*a*a - 3.0f*a + 1.0f);
    return (1.0f/6.0f)*(a*(a*(-a + 3.0f) - 3.0f) + 1.0f);   // optimized
}

float w1(float a)
{
    //    return (1.0f/6.0f)*(3.0f*a*a*a - 6.0f*a*a + 4.0f);
    return (1.0f/6.0f)*(a*a*(3.0f*a - 6.0f) + 4.0f);
}

float w2(float a)
{
    //    return (1.0f/6.0f)*(-3.0f*a*a*a + 3.0f*a*a + 3.0f*a + 1.0f);
    return (1.0f/6.0f)*(a*(a*(-3.0f*a + 3.0f) + 3.0f) + 1.0f);
}

float w3(float a)
{
    return (1.0f/6.0f)*(a*a*a);
}

// g0 and g1 are the two amplitude functions
float g0(float a)
{
    return w0(a) + w1(a);
}

float g1(float a)
{
    return w2(a) + w3(a);
}

// h0 and h1 are the two offset functions
float h0(float a)
{
    // note +0.5 offset to compensate for CUDA linear filtering convention
    return -1.0f + w1(a) / (w0(a) + w1(a)) + 0.5f;
}

float h1(float a)
{
    return 1.0f + w3(a) / (w2(a) + w3(a)) + 0.5f;
}

//https://ndotl.wordpress.com/2018/08/29/baking-artifact-free-lightmaps
float3 tex2DFastBicubicLightmap(float2 uv)
{
    #if defined(SHADER_API_D3D11) && defined(ENABLE_BICUBIC_LIGHTMAP)
    float width;
    float height;
    unity_Lightmap.GetDimensions(width, height);
    float x = uv.x * width;
    float y = uv.y * height;

    
    
    x -= 0.5f;
    y -= 0.5f;
    float px = floor(x);
    float py = floor(y);
    float fx = x - px;
    float fy = y - py;

    // note: we could store these functions in a lookup table texture, but maths is cheap
    float g0x = g0(fx);
    float g1x = g1(fx);
    float h0x = h0(fx);
    float h1x = h1(fx);
    float h0y = h0(fy);
    float h1y = h1(fy);

    float4 r = g0(fy) * ( g0x * UNITY_SAMPLE_TEX2D(unity_Lightmap, (float2(px + h0x, py + h0y) * 1.0f/width)) +
                         g1x * UNITY_SAMPLE_TEX2D(unity_Lightmap, (float2(px + h1x, py + h0y) * 1.0f/width))) +
                         g1(fy) * ( g0x * UNITY_SAMPLE_TEX2D(unity_Lightmap, (float2(px + h0x, py + h1y) * 1.0f/width)) +
                         g1x * UNITY_SAMPLE_TEX2D(unity_Lightmap, (float2(px + h1x, py + h1y) * 1.0f/width)));
    return DecodeLightmap(r);
    #else
    return DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, uv));
    #endif
}

float3 getLightmap(float2 uv, half3 worldNormal, float3 worldPos)
{
    float2 lightmapUV = uv * unity_LightmapST.xy + unity_LightmapST.zw;

#if defined(SHADER_API_MOBILE)
    half3 lightMap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapUV));
#else
    half3 lightMap = tex2DFastBicubicLightmap(lightmapUV) * (_LightmapMultiplier);
#endif


#ifdef DIRLIGHTMAP_COMBINED
    half4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, lightmapUV);
    lightMap = DecodeDirectionalLightmap(lightMap, bakedDirTex, worldNormal);
#endif

return lightMap;
}

// Get the most intense light Dir from probes OR from a light source. Method developed by Xiexe / Merlin
float3 getLightDir(bool lightEnv, float3 worldPos)
{
    //switch between using probes or actual light direction
    half3 lightDir = lightEnv ? UnityWorldSpaceLightDir(worldPos) : unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;

    return normalize(lightDir);
}

float3 getLightCol(bool lightEnv, float3 lightColor, float3 indirectDominantColor)
{
    float3 c = lightEnv ? lightColor : indirectDominantColor;
    return c;
}











float GSAA_Filament(float3 worldNormal,float perceptualRoughness) {
    // Kaplanyan 2016, "Stable specular highlights"
    // Tokuyoshi 2017, "Error Reduction and Simplification for Shading Anti-Aliasing"
    // Tokuyoshi and Kaplanyan 2019, "Improved Geometric Specular Antialiasing"

    // This implementation is meant for deferred rendering in the original paper but
    // we use it in forward rendering as well (as discussed in Tokuyoshi and Kaplanyan
    // 2019). The main reason is that the forward version requires an expensive transform
    // of the half vector by the tangent frame for every light. This is therefore an
    // approximation but it works well enough for our needs and provides an improvement
    // over our original implementation based on Vlachos 2015, "Advanced VR Rendering".

    float3 du = ddx(worldNormal);
    float3 dv = ddy(worldNormal);

    float variance = _specularAntiAliasingVariance * (dot(du, du) + dot(dv, dv));

    float roughness = perceptualRoughness * perceptualRoughness;
    float kernelRoughness = min(2.0 * variance, _specularAntiAliasingThreshold);
    float squareRoughness = saturate(roughness * roughness + kernelRoughness);

    return sqrt(sqrt(squareRoughness));
}



float GSAA_Valve(float3 vGeometricNormalWs,float3 vRoughness)
{
    float3 vNormalWsDdx = ddx( vGeometricNormalWs.xyz );
    float3 vNormalWsDdy = ddy( vGeometricNormalWs.xyz );
    float flGeometricRoughnessFactor = pow( saturate( max( dot( vNormalWsDdx.xyz, vNormalWsDdx.xyz ), dot( vNormalWsDdy.xyz, vNormalWsDdy.xyz ) ) ), 0.333 );

    return flGeometricRoughnessFactor;
}

float computeSpecularAO(float NoV, float ao, float roughness) {
    return clamp(pow(NoV + ao, exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
}

//https://forum.unity.com/threads/fixing-screen-space-directional-shadows-and-anti-aliasing.379902/
/*
float SSDirectionalShadowAA(float4 _ShadowCoord, sampler2D_float depthTex, float4 depthTextureTexelSize, sampler2D _ShadowMapTexture, half atten){
    half a = atten;
    float2 screenUV = _ShadowCoord.xy / _ShadowCoord.w;
    half shadow = tex2D(_ShadowMapTexture, screenUV).r;

    if(frac(_Time.x) > 0.5)
	    a = shadow;

    float fragDepth = _ShadowCoord.z / _ShadowCoord.w;
    float depth_raw = tex2D(depthTex, screenUV).r;

    float depthDiff = abs(fragDepth - depth_raw);
    float diffTest = 1.0 / 100000.0;

    if (depthDiff > diffTest){
	    float2 texelSize = depthTextureTexelSize.xy;
    	float4 offsetDepths = 0;

	    float2 uvOffsets[5] = {
	    float2(1.0, 0.0) * texelSize,
	    float2(-1.0, 0.0) * texelSize,
	    float2(0.0, 1.0) * texelSize,
	    float2(0.0, -1.0) * texelSize,
	    float2(0.0, 0.0)
	    };

    	offsetDepths.x = tex2D(depthTex, screenUV + uvOffsets[0]).r;
    	offsetDepths.y = tex2D(depthTex, screenUV + uvOffsets[1]).r;
	    offsetDepths.z = tex2D(depthTex, screenUV + uvOffsets[2]).r;
	    offsetDepths.w = tex2D(depthTex, screenUV + uvOffsets[3]).r;

    	float4 offsetDiffs = abs(fragDepth - offsetDepths);

    	float diffs[4] = {offsetDiffs.x, offsetDiffs.y, offsetDiffs.z, offsetDiffs.w};

    	int lowest = 4;
    	float tempDiff = depthDiff;
    	for (int i=0; i<4; i++){
		    if(diffs[i] < tempDiff){
    			tempDiff = diffs[i];
				lowest = i;
		    }
	    }

    a = tex2D(_ShadowMapTexture, screenUV + uvOffsets[lowest]).r;
    }
    return a;
}
*/







#endif
