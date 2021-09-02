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

void initBumpedNormalTangentBitangent(half4 normalMap, inout half3 bitangent, inout half3 tangent, inout half3 normal, half nScale, half orientation)
{

    normalMap.g = orientation ? normalMap.g : 1-normalMap.g;
    
    float3 tangentNormal = UnpackScaleNormal(normalMap, nScale);

    float3 calcedNormal = normalize
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

#define TRANSFORM(uv, tileOffset) (uv.xy * tileOffset.xy + tileOffset.zw) // because using ## wouldnt replace on lock in
#define TRANSFORMTEX(uv, tileOffset, transformTex) (uv.xy * tileOffset.xy * transformTex.xy + tileOffset.zw + transformTex.zw)



#endif
