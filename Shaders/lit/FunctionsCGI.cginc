// https://github.com/Xiexe/Unity-Lit-Shader-Templates/blob/master/LICENSE
// https://github.com/google/filament/blob/main/LICENSE
#define grayscaleVec half3(0.2125, 0.7154, 0.0721)
#define TAU 6.28318530718

#define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
// custom uv sample texture
// type 0: uv0 and locked to maintex tiling
// type 1: uv1 unlocked
// type 2: uv2 unlocked
// type 3: uv0 unlocked
// type 4: triplanar
// type 5: uv0 stochastic


float2 hash2D2D (float2 s)
{
    //magic numbers
    return frac(sin(glsl_mod(float2(dot(s, float2(127.1,311.7)), dot(s, float2(269.5,183.3))), 3.14159))*43758.5453);
}
#ifndef STOCHASTIC
float4 SampleTexture(Texture2D tex, float4 st, sampler s, int type)
{
    float4 sampledTexture = 0;

    switch(type)
    {
        case 0:
            sampledTexture = tex.Sample(s, input.coord0.xy * _MainTex_ST.xy + _MainTex_ST.zw + parallaxOffset);
            break;
        case 1:
            sampledTexture = tex.Sample(s, input.coord0.zw * st.xy + st.zw + parallaxOffset);
            break;
        case 2:
            sampledTexture = tex.Sample(s, input.coord1.xy * st.xy + st.zw + parallaxOffset);
            break;
        case 3:
            sampledTexture = tex.Sample(s, input.coord0.xy * st.xy + st.zw + parallaxOffset);
            break;
    }

    return sampledTexture;
}
#else
float4 SampleTexture(Texture2D tex, float4 st, sampler s, int type)
{
    st.xy = _Stochastic_ST.xy;
    st.zw = _Stochastic_ST.zw;
    float4 sampledTexture = 0;
    // https://www.reddit.com/r/Unity3D/comments/dhr5g2/i_made_a_stochastic_texture_sampling_shader/
    //triangle vertices and blend weights
    //BW_vx[0...2].xyz = triangle verts
    //BW_vx[3].xy = blend weights (z is unused)
    float4x3 BW_vx;

    //uv transformed into triangular grid space with UV scaled by approximation of 2*sqrt(3)
    float2 skewUV = mul(float2x2 (1.0 , 0.0 , -0.57735027 , 1.15470054), (input.coord0.xy * st.xy + st.zw) * 3.464);

    //vertex IDs and barycentric coords
    float2 vxID = float2 (floor(skewUV));
    float3 barry = float3 (frac(skewUV), 0);
    barry.z = 1.0-barry.x-barry.y;

    BW_vx = ((barry.z>0) ? 
        float4x3(float3(vxID, 0), float3(vxID + float2(0, 1), 0), float3(vxID + float2(1, 0), 0), barry.zyx) :
        float4x3(float3(vxID + float2 (1, 1), 0), float3(vxID + float2 (1, 0), 0), float3(vxID + float2 (0, 1), 0), float3(-barry.z, 1.0-barry.y, 1.0-barry.x)));

    //calculate derivatives to avoid triangular grid artifacts
    float2 dxu = ddx(input.coord0.xy * st.xy + st.zw);
    float2 dyu = ddy(input.coord0.xy * st.xy + st.zw);

    //blend samples with calculated weights
    sampledTexture =    mul(tex.SampleGrad(s, (input.coord0.xy * st.xy + st.zw) + hash2D2D(BW_vx[0].xy), dxu, dyu), BW_vx[3].x) + 
                        mul(tex.SampleGrad(s, (input.coord0.xy * st.xy + st.zw) + hash2D2D(BW_vx[1].xy), dxu, dyu), BW_vx[3].y) + 
                        mul(tex.SampleGrad(s, (input.coord0.xy * st.xy + st.zw) + hash2D2D(BW_vx[2].xy), dxu, dyu), BW_vx[3].z);

    return sampledTexture;
}
#endif


float4 SampleTexture(Texture2D tex, float4 st, int type)
{
    return SampleTexture(tex, st, defaultSampler, type);
}

// float4 SampleTexture(Texture2D tex, float4 st)
// {
//     return SampleTexture(tex, st, defaultSampler, 3);
// }

// float4 SampleTexture(Texture2D tex)
// {
//     return SampleTexture(tex, float4(1,1,0,0), defaultSampler, 3);
// }

#ifdef TEXTUREARRAY
float4 SampleTextureArray(Texture2DArray tex, float4 st, int type)
{
    float4 sampledTexture = 0;

    switch(type)
    {
        case 0:
            sampledTexture = UNITY_SAMPLE_TEX2DARRAY_SAMPLER(tex, _MainTexArray, float3(input.coord0.xy * _MainTex_ST.xy + _MainTex_ST.zw + parallaxOffset, textureIndex));
            break;
        case 1:
            sampledTexture = UNITY_SAMPLE_TEX2DARRAY_SAMPLER(tex, _MainTexArray, float3(input.coord0.zw * st.xy + st.zw + parallaxOffset, textureIndex));
            break;
        case 2:
            sampledTexture = UNITY_SAMPLE_TEX2DARRAY_SAMPLER(tex, _MainTexArray, float3(input.coord1.xy * st.xy + st.zw + parallaxOffset, textureIndex));
            break;
        case 3:
            sampledTexture = UNITY_SAMPLE_TEX2DARRAY_SAMPLER(tex, _MainTexArray, float3(input.coord0.xy * st.xy + st.zw + parallaxOffset, textureIndex));
            break;
    }
    return sampledTexture;
}
#endif

#if defined(TEXTUREARRAY)
float4 blendedTextureArray(Texture2DArray tex, float2 uv, float4 blendWeight)
{
    float4 bt;
    float4 w = blendWeight;

    float4 t[4];

    for(int j = 0; j < 4; j++) t[j] = 0;

    [unroll(4)]
    for(int k = 0; k < _ArrayCount; k++)
    {
        t[k] = UNITY_SAMPLE_TEX2DARRAY_SAMPLER(tex, _MainTexArray,float3(uv, k));
    }

    t[1] *= w.r;
    t[2] *= w.g;
    t[3] *= w.b;
    t[0] *= 1 - saturate(w.x + w.y + w.z);

    bt = t[0] + t[1] + t[2] + t[3];

    return bt;
}
#endif

float2 GetMainTexUV(int type)
{
    float2 uv = 0;

    switch(type)
    {
        case 0:
            uv =  input.coord0.xy * _MainTex_ST.xy + _MainTex_ST.zw + parallaxOffset;
            break;
        case 1:
            uv = input.coord0.zw * _MainTex_ST.xy + _MainTex_ST.zw + parallaxOffset;
            break;
        case 2:
            uv = input.coord1.xy * _MainTex_ST.xy + _MainTex_ST.zw + parallaxOffset;
            break;
    }
    return uv;
}

float CalculateMipLevel(float2 texture_coord)
{
    float2 dx = ddx(texture_coord);
    float2 dy = ddy(texture_coord);
    float delta_max_sqr = max(dot(dx, dx), dot(dy, dy));
    
    return max(0.0, 0.5 * log2(delta_max_sqr));
}

// https://github.com/DarthShader/Kaj-Unity-Shaders/blob/926f07a0bf3dc950db4d7346d022c89f9dfdb440/Shaders/Kaj/KajCore.cginc#L1041
#ifdef POINT
#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
        unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).r;
#endif
#ifdef SPOT
#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
        DECLARE_LIGHT_COORD(input, worldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#endif
#ifdef DIRECTIONAL
#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = 1;
#endif
#ifdef POINT_COOKIE
#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
        DECLARE_LIGHT_COORD(input, worldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).r * texCUBE(_LightTexture0, lightCoord).w;
#endif
#ifdef DIRECTIONAL_COOKIE
#define LIGHT_ATTENUATION_NO_SHADOW_MUL(destName, input, worldPos) \
        DECLARE_LIGHT_COORD(input, worldPos); \
        fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
        fixed destName = tex2D(_LightTexture0, lightCoord).w;
#endif


float pow5(float x)
{
    float x2 = x * x;
    return x2 * x2 * x;
}

float sq(float x)
{
    return x * x;
}
float3 F_Schlick(float u, float3 f0)
{
    return f0 + (1.0 - f0) * pow(1.0 - u, 5.0);
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
float3 tex2DFastBicubicLightmap(float2 uv, inout float4 bakedColorTex)
{
    #if defined(SHADER_API_D3D11) && defined(BICUBIC_LIGHTMAP)
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
    bakedColorTex = r;
    return DecodeLightmap(r);
    #else
    bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, uv);
    return DecodeLightmap(bakedColorTex);
    #endif
}

float3 getBoxProjection (float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax)
{
    #if defined(UNITY_SPECCUBE_BOX_PROJECTION)
        if (cubemapPosition.w > 0)
        {
            float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
            float scalar = min(min(factors.x, factors.y), factors.z);
            direction = direction * scalar + (position - cubemapPosition.xyz);
        }
    #endif

    return direction;
}

float computeSpecularAO(float NoV, float ao, float roughness) {
    return clamp(pow(NoV + ao, exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
}

float D_GGX_Anisotropic(float at, float ab, float ToH, float BoH, float NoH) {
    // Burley 2012, "Physically-Based Shading at Disney"

    // The values at and ab are perceptualRoughness^2, a2 is therefore perceptualRoughness^4
    // The dot product below computes perceptualRoughness^8. We cannot fit in fp16 without clamping
    // the roughness to too high values so we perform the dot product and the division in fp32
    float a2 = at * ab;
    float3 d = float3(ab * ToH, at * BoH, a2 * NoH);
    float d2 = dot(d, d);
    float b2 = a2 / d2;
    return a2 * b2 * b2 * (1.0 / UNITY_PI);
}

float V_SmithGGXCorrelated(float NoV, float NoL, float roughness) {
    float a2 = roughness * roughness;
    float GGXV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float GGXL = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / (GGXV + GGXL);
}

float V_SmithGGXCorrelated_Anisotropic(float at, float ab, float ToV, float BoV, float ToL, float BoL, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    // TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
    float lambdaV = NoL * length(float3(at * ToV, ab * BoV, NoV));
    float lambdaL = NoV * length(float3(at * ToL, ab * BoL, NoL));
    float v = 0.5 / (lambdaV + lambdaL);
    return saturate(v);
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

#ifdef PARALLAX
float3 CalculateTangentViewDir(float3 tangentViewDir)
{
    tangentViewDir = Unity_SafeNormalize(tangentViewDir);
    tangentViewDir.xy /= (tangentViewDir.z + 0.42);
	return tangentViewDir;
}

// parallax from mochie
// https://github.com/MochiesCode/Mochies-Unity-Shaders/blob/7d48f101d04dac11bd4702586ee838ca669f426b/Mochie/Standard%20Shader/MochieStandardParallax.cginc#L13
// MIT License

// Copyright (c) 2020 MochiesCode

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
float2 ParallaxOffsetMultiStep(float surfaceHeight, float strength, float2 uv, float3 tangentViewDir)
{
    float2 uvOffset = 0;
	float2 prevUVOffset = 0;
	float stepSize = 1.0/_ParallaxSteps;
	float stepHeight = 1;
	float2 uvDelta = tangentViewDir.xy * (stepSize * strength);
	float prevStepHeight = stepHeight;
	float prevSurfaceHeight = surfaceHeight;

    [unroll(50)]
    for (int j = 1; j <= _ParallaxSteps && stepHeight > surfaceHeight; j++){
        prevUVOffset = uvOffset;
        prevStepHeight = stepHeight;
        prevSurfaceHeight = surfaceHeight;
        uvOffset -= uvDelta;
        stepHeight -= stepSize;
        surfaceHeight = _ParallaxMap.Sample(sampler_MainTex, (uv + uvOffset)) + _ParallaxOffset;
    }
    [unroll(3)]
    for (int k = 0; k < 3; k++) {
        uvDelta *= 0.5;
        stepSize *= 0.5;

        if (stepHeight < surfaceHeight) {
            uvOffset += uvDelta;
            stepHeight += stepSize;
        }
        else {
            uvOffset -= uvDelta;
            stepHeight -= stepSize;
        }
        surfaceHeight = _ParallaxMap.Sample(sampler_MainTex, (uv + uvOffset)) + _ParallaxOffset;
    }

    return uvOffset;
}

float2 ParallaxOffset (float3 viewDirForParallax)
{
    viewDirForParallax = CalculateTangentViewDir(viewDirForParallax);

    float2 parallaxUV = input.coord0.xy * _MainTex_ST.xy + _MainTex_ST.zw;
    float h = _ParallaxMap.Sample(sampler_MainTex, parallaxUV);
    h = clamp(h, 0, 0.999);
    float2 offset = ParallaxOffsetMultiStep(h, _Parallax, parallaxUV, viewDirForParallax);

	return offset;
}
#endif

float shEvaluateDiffuseL1Geomerics_local(float L0, float3 L1, float3 n)
{
    // average energy
    float R0 = L0;
    
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

half D_GGX(half NoH, half roughness) {
    half a = NoH * roughness;
    half k = roughness / (1.0 - NoH * NoH + a * a);
    return k * k * (1.0 / UNITY_PI);
}

float3 getAnisotropicReflectionVector(float3 viewDir, float3 btg, float3 tg, float3 normal, float roughness)
{
    float3 anisotropicDirection = (_Anisotropy >= 0.0 ? btg : tg);
    float3 anisotropicTangent = cross(anisotropicDirection, viewDir);
    float3 anisotropicNormal = cross(anisotropicTangent, anisotropicDirection);
    float bendFactor = abs(_Anisotropy) * saturate(5.0 * roughness) ;
    float3 bentNormal = normalize(lerp(normal, anisotropicNormal, bendFactor));
    return reflect(-viewDir, bentNormal);
}

#ifdef DYNAMICLIGHTMAP_ON
float3 getRealtimeLightmap(float2 uv, float3 worldNormal, float2 parallaxOffset)
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

#if defined(VERTEXLIGHT_ON) && defined(UNITY_PASS_FORWARDBASE)
//Lifted vertex light support from XSToon: https://github.com/Xiexe/Xiexes-Unity-Shaders
//Returns the average color of all lights and writes to a struct contraining individual colors
float3 get4VertexLightsColFalloff(inout VertexLightInformation vLight, float3 worldPos, float3 normal, inout float4 vertexLightAtten)
{
    float3 lightColor = 0;
    #if defined(VERTEXLIGHT_ON)
        float4 toLightX = unity_4LightPosX0 - worldPos.x;
        float4 toLightY = unity_4LightPosY0 - worldPos.y;
        float4 toLightZ = unity_4LightPosZ0 - worldPos.z;

        float4 lengthSq = 0;
        lengthSq += toLightX * toLightX;
        lengthSq += toLightY * toLightY;
        lengthSq += toLightZ * toLightZ;

        float4 atten = 1.0 / (1.0 + lengthSq * unity_4LightAtten0);
        float4 atten2 = saturate(1 - (lengthSq * unity_4LightAtten0 / 25));
        atten = min(atten, atten2 * atten2);
        // Cleaner, nicer looking falloff. Also prevents the "Snapping in" effect that Unity's normal integration of vertex lights has.
        vertexLightAtten = atten;

        lightColor.rgb += unity_LightColor[0] * atten.x;
        lightColor.rgb += unity_LightColor[1] * atten.y;
        lightColor.rgb += unity_LightColor[2] * atten.z;
        lightColor.rgb += unity_LightColor[3] * atten.w;

        vLight.ColorFalloff[0] = unity_LightColor[0] * atten.x;
        vLight.ColorFalloff[1] = unity_LightColor[1] * atten.y;
        vLight.ColorFalloff[2] = unity_LightColor[2] * atten.z;
        vLight.ColorFalloff[3] = unity_LightColor[3] * atten.w;

        vLight.Attenuation[0] = atten.x;
        vLight.Attenuation[1] = atten.y;
        vLight.Attenuation[2] = atten.z;
        vLight.Attenuation[3] = atten.w;
    #endif
    return lightColor;
}

//Returns the average direction of all lights and writes to a struct contraining individual directions
float3 getVertexLightsDir(inout VertexLightInformation vLights, float3 worldPos, float4 vertexLightAtten)
{
    float3 dir = float3(0,0,0);
    float3 toLightX = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
    float3 toLightY = float3(unity_4LightPosX0.y, unity_4LightPosY0.y, unity_4LightPosZ0.y);
    float3 toLightZ = float3(unity_4LightPosX0.z, unity_4LightPosY0.z, unity_4LightPosZ0.z);
    float3 toLightW = float3(unity_4LightPosX0.w, unity_4LightPosY0.w, unity_4LightPosZ0.w);

    float3 dirX = toLightX - worldPos;
    float3 dirY = toLightY - worldPos;
    float3 dirZ = toLightZ - worldPos;
    float3 dirW = toLightW - worldPos;

    dirX *= length(toLightX) * vertexLightAtten.x;
    dirY *= length(toLightY) * vertexLightAtten.y;
    dirZ *= length(toLightZ) * vertexLightAtten.z;
    dirW *= length(toLightW) * vertexLightAtten.w;

    vLights.Direction[0] = dirX;
    vLights.Direction[1] = dirY;
    vLights.Direction[2] = dirZ;
    vLights.Direction[3] = dirW;

    dir = (dirX + dirY + dirZ + dirW) / 4;
    return dir;
}

void initVertexLights(float3 worldPos, float3 worldNormal, inout float3 vLight, inout float3 vertexLightColor)
{
    float3 vertexLightData = 0;
    float4 vertexLightAtten = float4(0,0,0,0);
    vertexLightColor = get4VertexLightsColFalloff(vertexLightInformation, worldPos, worldNormal, vertexLightAtten);
    float3 vertexLightDir = getVertexLightsDir(vertexLightInformation, worldPos, vertexLightAtten);
    [unroll(4)]
    for(int i = 0; i < 4; i++)
    {
        vertexLightData += saturate(dot(vertexLightInformation.Direction[i], worldNormal)) * vertexLightInformation.ColorFalloff[i];
    }
    vLight = vertexLightData;
}
#endif
#ifdef ENABLE_AUDIOLINK
void ApplyAudioLinkEmission(inout float3 emissionMap)
{
    float4 alEmissionMap = 1;
    #if defined(PROP_ALEMISSIONMAP)
        alEmissionMap = SampleTexture(_ALEmissionMap, _EmissionMap_ST, _EmissionMap_UV);
    #endif
    
    float alEmissionType = 0;
    float alEmissionBand = _ALEmissionBand;
    float alSmoothing = (1 - _ALSmoothing);
    float alemissionMask = ((alEmissionMap.b * 256) > 1 ) * alEmissionMap.a;
    

    switch(_ALEmissionType)
    {
        case 1:
            alEmissionType = alSmoothing * 15;
            alEmissionBand += ALPASS_FILTEREDAUDIOLINK.y;
            alemissionMask = alEmissionMap.b;
            break;
        case 2:
            alEmissionType = alEmissionMap.b * (128 *  (1 - alSmoothing));
            break;
        case 3:
            alEmissionType = alSmoothing * 15;
            alEmissionBand += ALPASS_FILTEREDAUDIOLINK.y;
            break;
    }

    float alEmissionSample = _ALEmissionType ? AudioLinkLerpMultiline(float2(alEmissionType , alEmissionBand)).r * alemissionMask : 1;
    emissionMap *= alEmissionSample;
}
#endif