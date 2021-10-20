// https://github.com/Xiexe/Unity-Lit-Shader-Templates/blob/master/LICENSE
// https://github.com/google/filament/blob/main/LICENSE
#define grayscaleVec half3(0.2125, 0.7154, 0.0721)
#define TAU 6.28318530718

#define glsl_mod(x,y) (((x)-(y)*floor((x)/(y))))
// custom uv sample texture
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
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
        // case 4:
        //     float3 n = abs(pixel.worldNormal);
        //     float3 w = n / (n.x + n.y + n.z);
        //     float4 tzy = tex.Sample(s, pixel.worldPos.zy * st.xy + st.zw);
        //     float4 txz = tex.Sample(s, pixel.worldPos.xz * st.xy + st.zw);
        //     float4 txy = tex.Sample(s, pixel.worldPos.xy * st.xy + st.zw);
        //     sampledTexture = tzy * w.x + txz * w.y + txy * w.z;
        //     break;
        case 4:
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
            break;
    }

    return sampledTexture;
}

float4 SampleTexture(Texture2D tex, float4 st, int type)
{
    return SampleTexture(tex, st, sampler_MainTex, type);
}

float4 SampleTexture(Texture2D tex, float4 st)
{
    return SampleTexture(tex, st, sampler_MainTex, 3);
}

float4 SampleTexture(Texture2D tex)
{
    return SampleTexture(tex, float4(1,1,0,0), sampler_MainTex, 3);
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