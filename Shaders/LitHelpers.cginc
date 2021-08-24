#ifndef LITHELPERS
#define LITHELPERS

float calcAlpha(half cutoff, half alpha, half mode)
{
    UNITY_BRANCH
    if(mode == 1)
    {
        if (_AlphaToMask == 2) alpha = (alpha - cutoff) / max(fwidth(alpha), 0.0001) + 0.5;
        if (_AlphaToMask == 0) clip(alpha - cutoff);
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

#define TRANSFORMTEX(uv, tileOffset) (uv.xy * tileOffset.xy + tileOffset.zw) // because using ## wouldnt replace on lock in
#define TRANSFORMMAINTEX(uv, tileOffset) (uv.xy * tileOffset.xy * _MainTex_ST.xy + tileOffset.zw + _MainTex_ST.zw)


half4 sampleTex(Texture2D tex, float4 tillingOffset, half uv, half3 worldPos, half3 worldNormal)
{
    half4 col = 0;
    if(uv == 3)
    {
        half3 weights = abs(worldNormal);
        weights = pow(weights, _TriplanarBlend);

        weights = weights / (weights.x + weights.y + weights.z);

        half2 uv_front = worldPos.xy * tillingOffset.xy * _MainTex_ST.xy+ tillingOffset.zw + _MainTex_ST.zw;
        half2 uv_side = worldPos.zy * tillingOffset.xy * _MainTex_ST.xy+ tillingOffset.zw + _MainTex_ST.zw;
        half2 uv_top = worldPos.xz * tillingOffset.xy * _MainTex_ST.xy + tillingOffset.zw + _MainTex_ST.zw;

        half4 col_front = UNITY_SAMPLE_TEX2D_SAMPLER(tex,_MainTex, uv_front) * weights.z;
        half4 col_side = UNITY_SAMPLE_TEX2D_SAMPLER(tex,_MainTex, uv_side) *  weights.x;
        half4 col_top = UNITY_SAMPLE_TEX2D_SAMPLER(tex,_MainTex, uv_top) * weights.y;

        col = (col_front + col_side + col_top);
    }

    else
    {
        col = UNITY_SAMPLE_TEX2D_SAMPLER(tex, _MainTex, uvs[uv] * tillingOffset.xy * _MainTex_ST.xy + tillingOffset.zw + _MainTex_ST.zw);
    }

    return col;

}



#endif
