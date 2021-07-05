Shader "VRStandard"
{

    Properties
    {
        
        [HideInInspector] shader_is_using_thry_editor("", Float)=1
        [ThryShaderOptimizerLockButton] _ShaderOptimizerEnabled ("", Float) = 0

        [HideInInspector] m_Main ("Main", Float) = 1
        _MainTex ("Albedo --{reference_property:_Color}", 2D) = "white" {}
        [HideInInspector] _Color ("Color", Color) = (1,1,1,1)
        
        [ToggleUI] _UseVertexColors ("Use Vertex Colors", Float) = 0
               
                
        
        
        
        [NoScaleOffset] _PackedTexture ("Mask Map--{on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnablePackedMode=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnablePackedMode=1}]}]} ", 2D) = "white" {}

        [HideInInspector] [ToggleUI] _EnableRoughnessMap ("Enable Roughness Map ", Float) = 0
        [NoScaleOffset] _RoughnessMap ("Roughness--{reference_property:_Roughness,on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableRoughnessMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableRoughnessMap=1}]}]} ", 2D) = "white" {}
        [HideInInspector]_Roughness ("Roughness", Range(0,1)) = 0.5

        
        [HideInInspector] [ToggleUI] _EnableMetallicMap ("Enable Metallic Map", Float) = 0
        [NoScaleOffset]_MetallicMap ("Metallic--{reference_property:_Metallic,on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableMetallicMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableMetallicMap=1}]}]} ", 2D) = "white" {}
        [HideInInspector]_Metallic ("Metallic", Range(0,1)) = 0
        
        [HideInInspector] [Toggle(_NORMALMAP)] _EnableNormalMap ("Enable Normal Map", Float) = 0
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
        [Toggle(UNITY_UI_ALPHACLIP)] _EnablePackedMode ("Packed Textures", Float) = 0
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
            Cull [_Cull]

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest

            #pragma shader_feature UNITY_UI_CLIP_RECT // GSAA
            #pragma shader_feature _NORMALMAP // normal map
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
            Blend One One
            Cull [_Cull]
            ZWrite Off

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma shader_feature UNITY_UI_CLIP_RECT // GSAA
            #pragma shader_feature _NORMALMAP // normal map
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
            ZWrite On ZTest LEqual
            Cull [_Cull]

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