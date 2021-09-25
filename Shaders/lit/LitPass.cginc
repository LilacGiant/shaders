#include "LitInputs.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;

    float2 uv0 : TEXCOORD0;
    #ifdef NEEDS_UV1
        float2 uv1 : TEXCOORD1;
    #endif
    #ifdef NEEDS_UV2
        float2 uv2 : TEXCOORD2;
    #endif
    

    #if !defined(UNITY_PASS_SHADOWCASTER)

        #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (PROP_BUMPMAP) || defined(ENABLE_MATCAP) || defined(ENABLE_PARALLAX) || defined (UNITY_PASS_META) || defined(BAKERY_INCLUDED)
            half4 tangent : TANGENT;
        #endif
    
        #ifdef PROP_ENABLEVERTEXCOLOR
            half4 color : COLOR;
        #endif
    #endif

    uint vertexId : SV_VertexID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 pos : SV_POSITION;

    #ifdef NEEDS_UV1
        float4 texcoord0 : TEXCOORD0;
    #else
        float2 texcoord0 : TEXCOORD0;
    #endif
    #ifdef NEEDS_UV2
        float4 texcoord1 : TEXCOORD1;
    #endif

    #if !defined(UNITY_PASS_SHADOWCASTER)

        #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (PROP_BUMPMAP) || defined(ENABLE_MATCAP) || defined (UNITY_PASS_META)
            float3 bitangent : TEXCOORD2;
            float3 tangent : TEXCOORD3;
        #endif

        float3 worldNormal : TEXCOORD4;
        float3 worldPos : TEXCOORD5;
    
        UNITY_SHADOW_COORDS(6)

        #ifdef USE_FOG
            UNITY_FOG_COORDS(7)
        #endif

        #if defined(ENABLE_PARALLAX) || defined(BAKERY_RNM)
            float3 viewDirForParallax : TEXCOORD8;
        #endif

        #ifdef PROP_ENABLEVERTEXCOLOR
            centroid half4 color : COLOR;
        #endif

        #ifdef CENTROID_NORMAL
            centroid float3 centroidWorldNormal : TEXCOORD9;
        #endif

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

    #ifdef NEEDS_UV1
    o.texcoord0.zw = v.uv1;
    #endif

    #ifdef NEEDS_UV2
    o.texcoord1.xy = v.uv2;
    #endif

    
    #if !defined(UNITY_PASS_SHADOWCASTER)
        float3 worldNormal = UnityObjectToWorldNormal(v.normal);

        #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (PROP_BUMPMAP) || defined(ENABLE_MATCAP)
            half3 tangent = UnityObjectToWorldDir(v.tangent);
            half3 bitangent = cross(tangent, worldNormal) * v.tangent.w;
            o.bitangent = bitangent;
            o.tangent = tangent;
        #endif

        o.worldNormal = worldNormal;
        #ifdef CENTROID_NORMAL
            o.centroidWorldNormal = worldNormal;
        #endif
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);

        #ifdef USE_FOG
            UNITY_TRANSFER_FOG(o, o.pos);
        #endif

         #if defined(ENABLE_PARALLAX) || defined(BAKERY_RNM)
            TANGENT_SPACE_ROTATION;
            o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
        #endif

        #ifdef PROP_ENABLEVERTEXCOLOR
            o.color = v.color;
        #endif

        UNITY_TRANSFER_SHADOW(o, o.texcoord0.xy);
    #else
        TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos);
    #endif


    return o;
}

#include "LitFunctions.cginc"
#include "LitFrag.cginc"