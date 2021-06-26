Shader "VR Standard"
{

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        
        _MetallicMap ("Metallic Map", 2D) = "white" {}
        [Gamma] _Metallic ("Metallic", Range(0,1)) = 0
        
        _RoughnessMap ("Roughness Map", 2D) = "white" {}
        _Roughness ("Roughness", Range(0,1)) = 0.5
        
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1

        

        
        
        [ToggleUI()] _GSAA("GSAA", int) = 0

        _specularAntiAliasingVariance ("Specular AA Variance", Range(0.0, 1.0)) = 0.01
        _specularAntiAliasingThreshold ("Specular AA Threshold", Range(0.0, 1.0)) = 0.1

        _OcclusionMap ("_OcclusionMap", 2D) = "white" {}
        _OcclusionStrength ("OcclusionStrength", Range(0, 1)) = 1

        [ToggleUI()] _SpecularHighlights("Specular Highlights", int) = 1
        [ToggleUI()] _GlossyReflections("Glossy Reflections", int) = 1
        _Reflectance ("Reflectance", Range(0,1)) = 0.5
        
        

        
        [ToggleUI] _OverrideQuest("", int) = 0
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
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest
            
            #pragma shader_feature UNITY_UI_CLIP_RECT // GSAA
            #pragma shader_feature _NORMALMAP // normal map
            #pragma shader_feature _METALLICGLOSSMAP // metalic map
            #pragma shader_feature _SPECGLOSSMAP // roughness map
            #pragma shader_feature _DETAIL_MULX2 // occlusion map
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF

            #pragma shader_feature PLATFORM_QUEST



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
            Tags { "LightMode"="ForwardAdd" }
            Blend One One
            ZWrite Off

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma shader_feature UNITY_UI_CLIP_RECT // GSAA
            #pragma shader_feature _NORMALMAP // normal map
            #pragma shader_feature _METALLICGLOSSMAP // metalic map
            #pragma shader_feature _SPECGLOSSMAP // roughness map
            #pragma shader_feature _DETAIL_MULX2 // occlusion Map
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature _REQUIRE_UV2 // anisotropy

            #pragma shader_feature PLATFORM_QUEST

            
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
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On ZTest LEqual
            Cull Back
            
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
    CustomEditor "z3y.VRSShaderEditor"
}