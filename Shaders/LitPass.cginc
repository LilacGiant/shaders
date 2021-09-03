#ifndef LITPASS
#define LITPASS

#include "LitInputs.cginc"
#include "UnityCG.cginc"
#include "AutoLight.cginc"
//#include "HLSLSupport.cginc"
#include "Lighting.cginc"
#include "LitHelpers.cginc"
#include "LitLighting.cginc"
#ifdef UNITY_PASS_META
#include "UnityMetaPass.cginc"
#endif




struct appdata
{
    float4 vertex : POSITION;
    half3 normal : NORMAL;
    #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (PROP_BUMPMAP) || defined(ENABLE_MATCAP)
    half4 tangent : TANGENT;
    #endif

    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;


    #ifdef ENABLE_VERTEXCOLOR
    half4 color : COLOR;
    #endif
    uint vertexId : SV_VertexID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 pos : SV_POSITION;

    float4 texcoord0 : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;

    #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (PROP_BUMPMAP) || defined(ENABLE_MATCAP)
        float3 bitangent : TEXCOORD2;
        float3 tangent : TEXCOORD3;
    #endif

    float3 worldNormal : TEXCOORD4;
    float3 worldPos : TEXCOORD5;

    #if !defined(UNITY_PASS_SHADOWCASTER)
        UNITY_SHADOW_COORDS(6)

        #ifdef USE_FOG
            UNITY_FOG_COORDS(7)
        #endif

        #ifdef ENABLE_PARALLAX
            float3 viewDirForParallax : TEXCOORD8;
        #endif

    #endif
    
    #ifdef ENABLE_VERTEXCOLOR
        centroid half4 color : COLOR;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

UNITY_INSTANCING_BUFFER_START(Props)
    //UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
UNITY_INSTANCING_BUFFER_END(Props)

v2f vert(appdata v)
{
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


    #ifdef UNITY_PASS_META
    o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
    #else
    o.pos = UnityObjectToClipPos(v.vertex);
    #endif

    o.texcoord0.xy = v.uv0;
    o.texcoord0.zw = v.uv1;
    o.texcoord1.xy = v.uv2;

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

        UNITY_TRANSFER_SHADOW(o, o.texcoord0.xy);

        #ifdef USE_FOG
            UNITY_TRANSFER_FOG(o, o.pos);
        #endif

        #ifdef ENABLE_PARALLAX
            TANGENT_SPACE_ROTATION;
            o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
        #endif
    #else
    TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos);
    #endif


    return o;
}

void initUVs(v2f i)
{
    uvs[0] = i.texcoord0.xy;
    uvs[1] = i.texcoord0.zw;
    uvs[2] = i.texcoord1.xy;
}



#include "LitFrag.cginc"

#endif