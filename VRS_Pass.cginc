﻿#ifndef VRS_PASS
#define VRS_PASS
#include "VRS_Inputs.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;

    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;

    float2 lightmapUV : TEXCOORD3;
    float2 realtimeLightmapUV : TEXCOORD4;


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
    float2 lightmapUV : TEXCOORD8;
    float2 realtimeLightmapUV : TEXCOORD9;

    #ifdef ENABLE_VERTEXCOLOR
    fixed4 color : COLOR;
    #endif
};


#include "VRS_Helpers.cginc"
#include "VRS_Lighting.cginc"
#include "VRS_Vert.cginc"
#include "VRS_Frag.cginc"

#endif