﻿#ifndef LITPASS
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
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
    {
    UNITY_POSITION(pos);
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;

    #if defined(ENABLE_REFLECTIONS) || defined(ENABLE_SPECULAR_HIGHLIGHTS) || defined (PROP_BUMPMAP) || defined(ENABLE_MATCAP)
    float3 bitangent : TEXCOORD3;
    float3 tangent : TEXCOORD4;
    #endif
    float3 worldNormal : TEXCOORD5;


    float3 worldPos : TEXCOORD6;
    #if !defined(UNITY_PASS_SHADOWCASTER)
    SHADOW_COORDS(7)
    #endif

    #ifdef ENABLE_VERTEXCOLOR
    centroid half4 color : COLOR;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

#include "LitVert.cginc"
#include "LitFrag.cginc"

#endif