Shader "VRStandard"
{

    Properties
    {
        
        [HideInInspector] shader_is_using_thry_editor("", Float)=1
        [ThryShaderOptimizerLockButton] _ShaderOptimizerEnabled ("", Float) = 0

        [HideInInspector] m_Main ("Main", Float) = 1
        
[ThryWideEnum(Opaque, 0, Cutout, 1, TransClipping, 9, Fade, 2, Transparent, 3, Additive, 4, Soft Additive, 5, Multiplicative, 6, 2x Multiplicative, 7)]_Mode("Rendering Preset--{on_value_actions:[ 
            {value:0,actions:[{type:SET_PROPERTY,data:render_queue=2000}, {type:SET_PROPERTY,data:render_type=Opaque},            {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=0},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=1}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:1,actions:[{type:SET_PROPERTY,data:render_queue=2450}, {type:SET_PROPERTY,data:render_type=TransparentCutout}, {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=.5}, {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=0},  {type:SET_PROPERTY,data:_AlphaToMask=1},  {type:SET_PROPERTY,data:_ZWrite=1}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:9,actions:[{type:SET_PROPERTY,data:render_queue=2450}, {type:SET_PROPERTY,data:render_type=TransparentCutout}, {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=5}, {type:SET_PROPERTY,data:_DstBlend=10}, {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=1}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:2,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=5}, {type:SET_PROPERTY,data:_DstBlend=10}, {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:3,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=10}, {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=1}]},
            {value:4,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=1},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:5,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:RenderType=Transparent},        {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=4}, {type:SET_PROPERTY,data:_DstBlend=1},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:6,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=2}, {type:SET_PROPERTY,data:_DstBlend=0},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:7,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=2}, {type:SET_PROPERTY,data:_DstBlend=3},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]}
        }]}]}", Int) = 0
        

        _Cutoff ("Alpha Cuttoff--{condition_show:{type:PROPERTY_BOOL,data:_Mode==1}}", Range(0, 1.001)) = 0.5

        _MainTex ("Albedo --{reference_property:_Color}", 2D) = "white" {}
        [HideInInspector] _Color ("Color", Color) = (1,1,1,1)
        
        [ToggleUI] _UseVertexColors ("Use Vertex Colors", Float) = 0
               
                
        
        
        
        //[NoScaleOffset] _PackedTexture ("Mask Map--{on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnablePackedMode=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnablePackedMode=1}]}]} ", 2D) = "white" {}

        [HideInInspector] [ToggleUI] _EnableRoughnessMap ("Enable Roughness Map ", Float) = 0
        [NoScaleOffset] _RoughnessMap ("Roughness--{reference_property:_Roughness,on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableRoughnessMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableRoughnessMap=1}]}]} ", 2D) = "white" {}
        [HideInInspector]_Roughness ("Roughness", Range(0,1)) = 0.5

        
        [HideInInspector] [ToggleUI] _EnableMetallicMap ("Enable Metallic Map", Float) = 0
        [NoScaleOffset]_MetallicMap ("Metallic--{reference_property:_Metallic,on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableMetallicMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableMetallicMap=1}]}]} ", 2D) = "white" {}
        [HideInInspector]_Metallic ("Metallic", Range(0,1)) = 0
        
        [HideInInspector] [ToggleUI] _EnableNormalMap ("Enable Normal Map", Float) = 0
        [NoScaleOffset] [Normal] _BumpMap ("Normal Map--{reference_property:_BumpScale,on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableNormalMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableNormalMap=1}]}]} ", 2D) = "bump" {}
        [HideInInspector] _BumpScale ("Bump Scale", Float) = 1
        






        

        [HideInInspector] [ToggleUI] _EnableOcclusion("Occlusion", Float) = 0
        [NoScaleOffset] _OcclusionMap ("Occlusion--{reference_property:_OcclusionStrength,on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableOcclusion=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableOcclusion=1}]}]} ", 2D) = "white" {}
        [HideInInspector] _OcclusionStrength ("OcclusionStrength", Range(0, 1)) = 1

        
        [HideInInspector] m_Specular ("Reflections And Specular Highlights", Float) = 0
        [Toggle(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Specular Highlights", Float) = 1
        [Toggle(_GLOSSYREFLECTIONS_OFF)] _GlossyReflections("Reflections", Float) = 1
        _Reflectance ("Reflectance", Range(0,1)) = 0.5
        
        
        [HideInInspector] m_ShaderFeatures ("Shader Features", Float) = 0
        [HideInInspector] m_start_GSAA ("Geometric Specular Anti-Aliasing --{reference_property:_GSAA}", Float) = 0
        [HideInInspector] [Toggle(UNITY_UI_CLIP_RECT)] _GSAA("GSAA", Float) = 0
        [PowerSlider(3)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.01
        [PowerSlider(3)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1
        [HideInInspector] m_end_GSAA ("", Float) = 0
        
        [HideInInspector] m_RenderingOptions ("Advanced Options", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [Enum(Thry.BlendOp)]_BlendOp ("RGB Blend Op", Int) = 0
        [Enum(Thry.BlendOp)]_BlendOpAlpha ("Alpha Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
        

//        [Toggle(UNITY_UI_ALPHACLIP)] _EnablePackedMode ("Packed Textures", Float) = 0
        [Toggle(_DETAIL_MULX2)] _BicubicLightmap ("Bicubic Lightmap Sampling", Float) = 0
        
        



    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "Queue" = "Geometry"
        }

        Pass
        {
            Name "FORWARD"
            Tags
            {
                "LightMode"="ForwardBase"
            }
            
            ZWrite [_ZWrite]
            Cull [_Cull]
            ZTest [_ZTest]
            
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend [_SrcBlend] [_DstBlend]

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest

            #pragma shader_feature UNITY_UI_CLIP_RECT // GSAA
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature UNITY_UI_ALPHACLIP
            #pragma shader_feature _DETAIL_MULX2


            #ifndef UNITY_PASS_FORWARDBASE
            #define UNITY_PASS_FORWARDBASE
            #endif


            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;

                float3 bitangent : TEXCOORD3;
                float3 tangent : TEXCOORD4;
                float3 worldNormal : TEXCOORD5;

                float3 worldPos : TEXCOORD6;
                SHADOW_COORDS(7)
            };


            #include "VRS_Pass.cginc"
            ENDCG
        }

        Pass
        {
            Name "FWDADD"
            Tags
            {
                "LightMode"="ForwardAdd"
            }
            ZWrite Off
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend One One
            Cull [_Cull]
            ZTest [_ZTest]

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma shader_feature UNITY_UI_CLIP_RECT // GSAA
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature UNITY_UI_ALPHACLIP

            #ifndef UNITY_PASS_FORWARDADD
            #define UNITY_PASS_FORWARDADD
            #endif


            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;

                float3 bitangent : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;

                float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            #include "VRS_Pass.cginc"
            ENDCG
        }


        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode"="ShadowCaster"
            }
            AlphaToMask Off
            ZWrite [_ZWrite]
            Cull [_Cull]
            ZTest [_ZTest]

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

            #ifndef UNITY_PASS_SHADOWCASTER
            #define UNITY_PASS_SHADOWCASTER
            #endif


            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 bitangent : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };


            #include "VRS_Pass.cginc"
            ENDCG
        }

    }
    FallBack "Diffuse"
    CustomEditor "Thry.ShaderEditor"
}