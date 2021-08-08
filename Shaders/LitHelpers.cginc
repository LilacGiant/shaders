#ifndef LITHELPERS
#define LITHELPERS

float calcAlpha(float cutoff, float alpha, float mode)
{
    UNITY_BRANCH
    if(mode==1)
    {
        clip(alpha - cutoff);
        return alpha;
        break;
    }
    else return alpha;

    

}

void initBumpedNormalTangentBitangent(float4 normalMap, inout float3 bitangent, inout float3 tangent, inout float3 normal, float3 nScale, float orientation)
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

  


#endif
