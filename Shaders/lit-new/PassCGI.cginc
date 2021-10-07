#include "UnityCG.cginc"
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"

#include "ConfigCGI.cginc"
#include "InputsCGI.cginc"
#include "FunctionsCGI.cginc"

#if defined(DYNAMICLIGHTMAP_ON)
    #define NEEDS_UV2
#endif

#if defined(NORMALMAP)
    #ifndef NEEDS_TANGENT_BITANGENT
        #define NEEDS_TANGENT_BITANGENT
    #endif
#endif

#if defined(SPECULAR_HIGHLIGHTS) || defined(REFLECTIONS)
    #ifdef UNITY_PASS_FORWARDBASE
        #ifndef NEEDS_TANGENT_BITANGENT
            #define NEEDS_TANGENT_BITANGENT
        #endif
    #endif
#endif

struct appdata
{
    float4 vertex : POSITION;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float3 normal : NORMAL;


    #ifdef NEEDS_UV2
        float2 uv2 : TEXCOORD2;
    #endif

    #if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)

        #if defined (NEEDS_TANGENT_BITANGENT)
            half4 tangent : TANGENT;
        #endif

    #endif

    uint vertexId : SV_VertexID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 pos : SV_POSITION;
    float4 coord0 : TEXCOORD0;

    #ifdef NEEDS_UV2
        float2 coord0 : TEXCOORD1;
    #endif

    #if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
        float3 worldNormal : TEXCOORD2;
        float4 worldPos : TEXCOORD3;
        UNITY_SHADOW_COORDS(4)

        #if defined(NEEDS_TANGENT_BITANGENT)
            float3 bitangent : TEXCOORD5;
            float3 tangent : TEXCOORD6;
        #endif

        #if defined(LIGHTMAP_SHADOW_MIXING) && defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) && defined(LIGHTMAP_ON)
            float4 screenPos : TEXCOORD10;
        #endif
    #endif

    

    UNITY_FOG_COORDS(1)
    UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

// UNITY_INSTANCING_BUFFER_START(Props)
//     UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
// UNITY_INSTANCING_BUFFER_END(Props)



v2f vert (appdata v)
{
    v2f o;
    // UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    
    o.coord0.xy = TRANSFORM_TEX(v.uv0, _MainTex);
    o.coord0.zw = v.uv1;

    #ifdef NEEDS_UV2
        o.coord1.xy = v.uv2;
    #endif

    #if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
        o.pos = UnityObjectToClipPos(v.vertex);
        o.worldNormal = UnityObjectToWorldNormal(v.normal);
        o.worldPos = mul(unity_ObjectToWorld, v.vertex);

        #if defined(NEEDS_TANGENT_BITANGENT)
            o.tangent = UnityObjectToWorldDir(v.tangent);
            o.bitangent = cross(o.tangent.xyz, o.worldNormal) * v.tangent.w;
        #endif

        #if defined(LIGHTMAP_SHADOW_MIXING) && defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) && defined(LIGHTMAP_ON)
            o.screenPos = ComputeScreenPos(o.pos);
        #endif

        UNITY_TRANSFER_SHADOW(o, v.uv1);
    #else
        o.pos = UnityClipSpaceShadowCasterPos(v.vertex, v.normal);
        o.pos = UnityApplyLinearShadowBias(o.pos);
        TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos);
    #endif

    UNITY_TRANSFER_FOG(o,o.vertex);
    return o;
}

#include "CoreCGI.cginc"