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
    float3 normal : NORMAL;
    float4 tangent : TANGENT;

    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;

    #ifdef ENABLE_VERTEXCOLOR
    fixed4 color : COLOR;
    #endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
    {
    float4 pos : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;

    float3 bitangent : TEXCOORD3;
    float3 tangent : TEXCOORD4;
    float3 worldNormal : TEXCOORD5;

    float3 worldPos : TEXCOORD6;
    #ifdef UNITY_PASS_FORWARDBASE
    SHADOW_COORDS(7)
    #endif

    #ifdef ENABLE_VERTEXCOLOR
    fixed4 color : COLOR;
    #endif
};

#include "LitVert.cginc"
#include "LitFrag.cginc"

#endif