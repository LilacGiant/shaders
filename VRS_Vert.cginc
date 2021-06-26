#ifndef VRS_VERT
#define VRS_VERT

v2f vert(appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);

    #if defined(UNITY_PASS_FORWARDBASE)
    o.uv1 = v.uv1;
    o.uv2 = v.uv2;
    #endif


    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    float3 tangent = UnityObjectToWorldDir(v.tangent);
    float3 bitangent = cross(tangent, worldNormal) * v.tangent.w;

    o.bitangent = bitangent;
    o.tangent = tangent;
    o.worldNormal = worldNormal;


    o.worldPos = mul(unity_ObjectToWorld, v.vertex);

    #if !defined(UNITY_PASS_SHADOWCASTER)
    UNITY_TRANSFER_SHADOW(o, o.uv);
    #else
    TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos);
    #endif

    return o;
}
#endif