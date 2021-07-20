#ifndef LITPASS
#define LITPASS

#include "LitInputs.cginc"
#include "UnityCG.cginc"
#include "AutoLight.cginc"
#include "Lighting.cginc"
#include "LitHelpers.cginc"
#include "LitLighting.cginc"

struct appdata
{
    float4 vertex : POSITION;
    half3 normal : NORMAL;
    #if defined(_GLOSSYREFLECTIONS_OFF) || defined(_SPECULARHIGHLIGHTS_OFF) || defined (ENABLE_NORMALMAP)
    half4 tangent : TANGENT;
    #endif

    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;


    #ifdef ENABLE_VERTEXCOLOR
    half4 color : COLOR;
    #endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
    {
    UNITY_POSITION(pos);
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;

    #if defined(_GLOSSYREFLECTIONS_OFF) || defined(_SPECULARHIGHLIGHTS_OFF) || defined (ENABLE_NORMALMAP)
    float3 bitangent : TEXCOORD3;
    float3 tangent : TEXCOORD4;
    #endif
    float3 worldNormal : TEXCOORD5;

    float3 worldPos : TEXCOORD6;
    #if !defined(UNITY_PASS_SHADOWCASTER)
    SHADOW_COORDS(7)
    #endif

    #ifdef ENABLE_VERTEXCOLOR
    half4 color : COLOR;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

#include "LitVert.cginc"
#include "LitFrag.cginc"

#endif