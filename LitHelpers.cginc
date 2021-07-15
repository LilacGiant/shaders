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
    switch(orientation){
        case 0:
            normalMap.g = 1- normalMap.g;
            break;
        case 1:
            break; 
    }
    
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




#endif
