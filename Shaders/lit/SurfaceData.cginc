struct SurfaceData
{
    float3 albedo;
    float3 tangentNormal;
    float3 emission;
    float metallic;
    float perceptualRoughness;
    float occlusion;
    float reflectance;
    float alpha;
    float2 anisotropicDirection;
    float anisotropy;
};

void InitializeDefaultSurfaceData(inout SurfaceData surf)
{
    surf.albedo = 1;
    surf.tangentNormal = float3(0,0,1);
    surf.emission = 0;
    surf.metallic = 0;
    surf.perceptualRoughness = 0;
    surf.occlusion = 1;
    surf.reflectance = 0.5;
    surf.alpha = 1;
    surf.anisotropicDirection = 1;
    surf.anisotropy = 0;

}