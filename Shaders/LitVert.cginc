#ifndef LITVERT
#define LITVERT

v2f vert(appdata v)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    

    #ifdef UNITY_PASS_META
    o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
    #else
    o.pos = UnityObjectToClipPos(v.vertex);
    #endif

    o.uv0 = v.uv0;
    o.uv1 = v.uv1;
    o.uv2 = v.uv2;

    #ifdef ENABLE_VERTEXCOLOR
    o.color = v.color;
    #endif

    half3 worldNormal = UnityObjectToWorldNormal(v.normal);
    #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (PROP_BUMPMAP) || defined(ENABLE_MATCAP)
    half3 tangent = UnityObjectToWorldDir(v.tangent);
    half3 bitangent = cross(tangent, worldNormal) * v.tangent.w;

    o.bitangent = bitangent;
    o.tangent = tangent;
    #endif
    o.worldNormal = worldNormal;

    o.worldPos = mul(unity_ObjectToWorld, v.vertex);




    #if !defined(UNITY_PASS_SHADOWCASTER)
    UNITY_TRANSFER_SHADOW(o, o.uv0);
    #else
    TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos);
    #endif

    
    
    return o;
}
#endif
