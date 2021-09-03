#ifndef LITHELPERS
#define LITHELPERS

float calcAlpha(half cutoff, half alpha)
{
    UNITY_BRANCH
    if(_Mode == 1)
    {
        switch(_AlphaToMask)
        {
            case 0:
                clip(alpha - cutoff);
                break;
            case 1:
                clip(alpha - 0.01);
                break;
            case 2:
                alpha = (alpha - cutoff) / max(fwidth(alpha), 0.0001) + 0.5;
                clip(alpha - 0.01);
                break;
        }

    }
    return alpha;
}

void initNormalMap(half4 normalMap, inout half3 bitangent, inout half3 tangent, inout half3 normal, half4 detailNormalMap)
{
    normalMap.g = _NormalMapOrientation ? normalMap.g : 1-normalMap.g;

    half3 tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);

    #if defined(PROP_DETAILMAP) && !defined(SHADER_API_MOBILE)
        detailNormalMap.g = 1-detailNormalMap.g;
        half3 detailNormal = UnpackScaleNormal(detailNormalMap, _DetailNormalScale);
        tangentNormal = BlendNormals(tangentNormal, detailNormal);
    #endif

    half3 calcedNormal = normalize
    (
		tangentNormal.x * tangent +
		tangentNormal.y * bitangent +
		tangentNormal.z * normal
    );

    normal = calcedNormal;
    tangent = cross(normal, bitangent);
    bitangent = cross(normal, tangent);    
}





bool isInMirror()
{
    return unity_CameraProjection[2][0] != 0.f || unity_CameraProjection[2][1] != 0.f;
}

float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

half BlendMode_Overlay(half base, half blend)
{
	return (base <= 0.5) ? 2*base*blend : 1 - 2*(1-base)*(1-blend);
}

half3 BlendMode_Overlay(half3 base, half3 blend)
{
    return half3(   BlendMode_Overlay(base.r, blend.r),
                    BlendMode_Overlay(base.g, blend.g),
                    BlendMode_Overlay(base.b, blend.b));
}

float2 Rotate(float2 coords, float rot){
	rot *= (UNITY_PI/180.0);
	float sinVal = sin(rot);
	float cosX = cos(rot);
	float2x2 mat = float2x2(cosX, -sinVal, sinVal, cosX);
	mat = ((mat*0.5)+0.5)*2-1;
	return mul(coords, mat);
}


#define TRANSFORM(uv, tileOffset) (uv.xy * tileOffset.xy + tileOffset.zw + parallaxOffset) // because using ## wouldnt replace on lock in
#define TRANSFORMTEX(uv, tileOffset, transformTex) (uv.xy * tileOffset.xy * transformTex.xy + tileOffset.zw + transformTex.zw + parallaxOffset)


#define MAIN_TEX(tex, sampl, texUV, texST) (tex.Sample(sampl, TRANSFORM(texUV.xy, texST)))

#define NOSAMPLER_TEX(tex, texUV, texST, mainST) (tex.Sample(sampler_MainTex, TRANSFORMTEX(texUV.xy, texST, mainST)))

#ifdef ENABLE_PARALLAX

float3 CalculateTangentViewDir(float3 tangentViewDir)
{
    tangentViewDir = Unity_SafeNormalize(tangentViewDir);
    tangentViewDir.xy /= (tangentViewDir.z + 0.42);
	return tangentViewDir;
}

// uwu https://github.com/MochiesCode/Mochies-Unity-Shaders/blob/7d48f101d04dac11bd4702586ee838ca669f426b/Mochie/Standard%20Shader/MochieStandardParallax.cginc#L13
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
        surfaceHeight = _ParallaxMap.Sample(sampler_MainTex, (uv.xy * _MainTex_ST.xy + _MainTex_ST.zw + uvOffset)) + _ParallaxOffset;
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
        surfaceHeight = _ParallaxMap.Sample(sampler_MainTex, (uv.xy * _MainTex_ST.xy + _MainTex_ST.zw + uvOffset)) + _ParallaxOffset;
    }

    return uvOffset;
}

float2 ParallaxOffset (float2 texcoords, half3 viewDir)
{
    float h = _ParallaxMap.Sample(sampler_MainTex, (texcoords.xy * _MainTex_ST.xy + _MainTex_ST.zw)) + _ParallaxOffset;
    h = clamp(h, 0, 0.999);
    float2 offset = ParallaxOffsetMultiStep(h, _Parallax, texcoords.xy, viewDir);

	return offset;
}

#endif

#endif
