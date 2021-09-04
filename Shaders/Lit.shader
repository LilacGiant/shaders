Shader " Lit"
{

    Properties
    {
        _ShaderOptimizerEnabled ("", Float) = 0

        [Enum(Opaque, 0, Cutout, 1, Fade, 2, Transparent, 3)] _Mode("Rendering Mode", Int) = 0
        
        [Enum(Off, 0, On, 1, Sharpened, 2)] _AlphaToMask ("Alpha To Coverage", Float) = 0
        _Cutoff ("Alpha Cuttoff", Range(0.001, 1)) = 0.5

        _MainTex ("Base Map", 2D) = "white" {}
        [HideInInspector] _Color ("Base Color", Color) = (1,1,1,1)
        [HideInInspector] _Saturation ("Saturation", Range(-1,1)) = 0
        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2)] _MainTexUV ("UV", Int) = 0
        
        [HideInInspector] [ToggleUI] _EnableVertexColor ("Vertex Colors Mulitply Base", Float) = 0
               
        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Occlusion ("Occlusion", Range(0,1)) = 0


        _MetallicGlossMap ("Mask Map:Metallic(R), Occlusion(G), Detail Mask(B), Smoothness(A)", 2D) = "white" {}
        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2)] _MetallicGlossMapUV ("UV", Int) = 0


        _SmoothnessMap ("Smoothness Map", 2D) = "white" {}
        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2)] _SmoothnessMapUV ("UV", Int) = 0
        [HideInInspector] [ToggleUI] _GlossinessInvert ("Invert Smoothness", Float) = 0

        _MetallicMap ("Metallic Map", 2D) = "white" {}
        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2)] _MetallicMapUV ("UV", Int) = 0

        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2)] _OcclusionMapUV ("UV", Int) = 0

        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        [HideInInspector] _BumpScale ("Bump Scale", Range(0,10)) = 0
        [HideInInspector] [Enum(OpenGL, 0, Direct3D, 1)] _NormalMapOrientation ("Orientation", Int) = 0
        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2)] _BumpMapUV ("UV", Int) = 0

        [ToggleUI] _EnableEmission ("Emission", Float) = 0
        _EmissionMap ("Emission Map", 2D) = "white" {}
        [HideInInspector] [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)
        [HideInInspector] [Enum(UV0, 0, UV1, 1, UV2, 2)] _EmissionMapUV ("UV", Int) = 0

        
        [Enum(Default, 0, Light Probes, 1)] _GetDominantLight ("Dominant Light", Int) = 0
        _FresnelColor ("Sheen Color", Color) = (1,1,1,1)
        _Reflectance ("Reflectance", Range(0,1)) = 0.40
        _Anisotropy ("Anisotropy", Range(-1,1)) = 0


        [Toggle(ENABLE_SPECULAR_HIGHLIGHTS)] _SpecularHighlights("Specular Highlights", Float) = 1
        [Toggle(ENABLE_REFLECTIONS)] _GlossyReflections("Reflections", Float) = 1


        [HideInInspector] [Toggle(ENABLE_GSAA)] _GSAA ("Geometric Specular AA", Float) = 0
        [PowerSlider(3)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.15
        [PowerSlider(3)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1
        
        [HideInInspector] [Toggle(ENABLE_MATCAP)] _EnableMatcap ("Matcap", Float) = 0
        [NoScaleOffset] _MatCap ("Matcap", 2D) = "white" {}
        _MatCapReplace ("Intensity", Range(0.0, 1.0)) = 1

        
        _LightmapMultiplier ("Lightmap Multiplier", Range(0, 2)) = 1
        _SpecularOcclusion ("Specular Occlusion", Range(0, 1)) = 0

        [Toggle(ENABLE_BICUBIC_LIGHTMAP)] _BicubicLightmap ("Bicubic Lightmap Interpolation", Float) = 0
        [ToggleUI] _LightProbeMethod ("Non-linear Light Probe SH", Float) = 0

        


        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("RGB Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOpAlpha ("Alpha Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0

        [Enum(None, 0, ACES, 1)] _TonemappingMode ("Tonemapping Mode", Int) = 0
        _Contribution ("Contribution", Range(0, 1)) = 1



        [Toggle(ENABLE_PACKED_MODE)] _EnablePackedMode ("Packed Mode", Float) = 1       

        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2

        [Toggle(ENABLE_PARALLAX)] _EnableParallax ("Parallax", Float) = 0  
        _Parallax ("Height Scale", Range (0, 0.2)) = 0.02
        _ParallaxMap ("Height Map", 2D) = "black" {}
        [IntRange] _ParallaxSteps ("Parallax Steps", Range(1,50)) = 25
        _ParallaxOffset ("Parallax Offset", Range(-1, 1)) = 0


        _DetailMap ("Detail Map:Desaturated Albedo(R), Normal Y(G), Smoothness(B), Normal X(A)", 2D) = "linearGrey" {}
        [Enum(UV0, 0, UV1, 1, UV2, 2)] _DetailMapUV ("UV", Int) = 0
        _DetailAlbedoScale ("Albedo Scale", Range(0.0, 2.0)) = 1
        _DetailNormalScale ("Normal Scale", Range(0.0, 2.0)) = 0
        _DetailSmoothnessScale ("Smoothness Scale", Range(0.0, 2.0)) = 1
        
        
        [Toggle(ENABLE_REFRACTION)] _EnableRefraction ("Fake Refraction", Float) = 0
        [PowerSlider(0.25)] _Refraction ("Refraction", Range(0.0, 1)) = 0.9



    }

    SubShader //pc shader
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
            AlphaToMask [_AlphaToMask]
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend [_SrcBlend] [_DstBlend]

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers gles3
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #pragma shader_feature_local ENABLE_GSAA
            #pragma shader_feature_local ENABLE_SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local ENABLE_REFLECTIONS
            #pragma shader_feature_local ENABLE_PACKED_MODE
            #pragma shader_feature_local ENABLE_BICUBIC_LIGHTMAP
            #pragma shader_feature_local ENABLE_MATCAP
            #pragma shader_feature_local ENABLE_PARALLAX
            #pragma shader_feature_local ENABLE_REFRACTION


            #ifndef UNITY_PASS_FORWARDBASE
            #define UNITY_PASS_FORWARDBASE
            #endif

            #include "LitPass.cginc"
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
            AlphaToMask [_AlphaToMask]

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers gles3
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #pragma shader_feature_local ENABLE_SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local ENABLE_PACKED_MODE
            #pragma shader_feature_local ENABLE_PARALLAX


            #ifndef UNITY_PASS_FORWARDADD
            #define UNITY_PASS_FORWARDADD
            #endif

            #include "LitPass.cginc"
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
            ZWrite On
            Cull [_Cull]
            ZTest LEqual

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment ShadowCasterfrag
            #pragma exclude_renderers gles3
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

            #ifndef UNITY_PASS_SHADOWCASTER
            #define UNITY_PASS_SHADOWCASTER
            #endif

            #include "LitPass.cginc"
            ENDCG
        }

        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }

            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local ENABLE_PACKED_MODE
            #pragma shader_feature EDITOR_VISUALIZATION

            #ifndef UNITY_PASS_META
            #define UNITY_PASS_META
            #endif

            #include "LitPass.cginc"
            ENDCG
        }

    }

    SubShader // quest shader
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
            AlphaToMask [_AlphaToMask]

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma only_renderers gles3
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #pragma shader_feature_local ENABLE_SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local ENABLE_REFLECTIONS
            #pragma shader_feature_local ENABLE_PACKED_MODE
            #pragma shader_feature_local ENABLE_MATCAP
            #pragma shader_feature_local ENABLE_REFRACTION


            #ifndef UNITY_PASS_FORWARDBASE
            #define UNITY_PASS_FORWARDBASE
            #endif

            #include "LitPass.cginc"
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
            AlphaToMask [_AlphaToMask]


            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma only_renderers gles3
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #pragma shader_feature_local ENABLE_SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local ENABLE_PACKED_MODE


            #ifndef UNITY_PASS_FORWARDADD
            #define UNITY_PASS_FORWARDADD
            #endif

            #include "LitPass.cginc"
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
            ZWrite On
            Cull [_Cull]
            ZTest LEqual


            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment ShadowCasterfrag
            #pragma only_renderers gles3
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing

            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

            #ifndef UNITY_PASS_SHADOWCASTER
            #define UNITY_PASS_SHADOWCASTER
            #endif

            #include "LitPass.cginc"
            ENDCG
        }

    }

    FallBack "Diffuse"
    CustomEditor "Shaders.Lit.ShaderEditor"
}