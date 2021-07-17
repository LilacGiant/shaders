#ifndef LITVERT
#define LITVERT

v2f vert(appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv0 = v.uv0;
    o.uv1 = v.uv1;
    o.uv2 = v.uv2;

    #ifdef ENABLE_VERTEXCOLOR
    o.color = v.color;
    #endif


    half3 worldNormal = UnityObjectToWorldNormal(v.normal);
    half3 tangent = UnityObjectToWorldDir(v.tangent);
    half3 bitangent = cross(tangent, worldNormal) * v.tangent.w;

    o.bitangent = bitangent;
    o.tangent = tangent;
    o.worldNormal = worldNormal;

    o.worldPos = mul(unity_ObjectToWorld, v.vertex);

    #if !defined(UNITY_PASS_SHADOWCASTER)
    UNITY_TRANSFER_SHADOW(o, o.uv);
    #else
    TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos);
    #endif

    
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    return o;
}
#endif