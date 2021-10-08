Shader "z3y/Simple Lit"
{
    Properties
    {
        [Enum(Opaque, 0, Cutout, 1, Fade, 2, Transparent, 3, Alpha To Coverage, 4,  Alpha To Coverage Sharpened, 5)] _Mode("Rendering Mode", Int) = 0
        [Enum(Off, 0, On, 1)] _AlphaToMask ("Alpha To Coverage", Int) = 0
        _Cutoff ("Alpha Cuttoff", Range(0, 1)) = 0.5

        _MainTex ("Base Map", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)
        _Saturation ("Saturation", Range(-1,1)) = 0

        
        // [Toggle(MASKMAP)] _EnableMaskMap ("_EnableMaskMap", Int) = 0
        _MetallicGlossMap ("Mask Map:Metallic(R), Occlusion(G), Detail Mask(B), Smoothness(A)", 2D) = "white" {}
        [Gamma] _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Occlusion ("Occlusion", Range(0,1)) = 0

        
        // [Toggle(NORMALMAP)] _EnableNormalMap ("_EnableNormalMap", Int) = 0
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Range(0,10)) = 1

        // [Toggle(EMISSIONMAP)] _EnableEmissionMap ("_EnableEmissionMap", Int) = 0
        _EmissionMap ("Emission Map", 2D) = "white" {}
        [Toggle(EMISSION_BASE)] _EnableEmissionBase ("Multiply Base", Int) = 0
        [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)


        
        [Toggle(SPECULAR_HIGHLIGHTS)] _SpecularHighlights ("Specular Highlights", Int) = 1
        [Toggle(REFLECTIONS)] _GlossyReflections ("Reflections", Int) = 1
        _Reflectance ("Reflectance", Range(0,1)) = 0.5
        _FresnelColor ("Reflections Tint", Color) = (1,1,1,1)

        
        // [Toggle(DETAILMAP)] _EnableDetailMap ("_EnableDetailMap", Int) = 0
        // [Toggle(DETAILMAP_UV1)] _EnableDetailMapUV1 ("_EnableDetailMapUV1", Int) = 0
        [Enum(UV0, 0, UV1, 1)] _DetailMapUV ("Detail UV", Int) = 0
        _DetailMap ("Detail Map:Desaturated Albedo(R), Normal Y(G), Smoothness(B), Normal X(A)", 2D) = "linearGrey" {}
        _DetailAlbedoScale ("Albedo Scale", Range(0.0, 2.0)) = 1
        _DetailNormalScale ("Normal Scale", Range(0.0, 2.0)) = 0
        _DetailSmoothnessScale ("Smoothness Scale", Range(0.0, 2.0)) = 1

        
        [Toggle(GEOMETRIC_SPECULAR_AA)] _GSAA ("Geometric Specular AA", Int) = 0
        [PowerSlider(3)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.15
        [PowerSlider(3)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1

        
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOpAlpha ("Blend Op Alpha", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
    
    }

    SubShader
    {

        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode"="ForwardBase" }
            
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
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile _ VERTEXLIGHT_ON

            
            #pragma shader_feature_local _ CUTOUT FADE TRANSPARENT A2C_SHARPENED
            #pragma shader_feature_local MASKMAP
            #pragma shader_feature_local _ DETAILMAP DETAILMAP_UV1
            #pragma shader_feature_local NORMALMAP
            #pragma shader_feature_local SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local REFLECTIONS
            #pragma shader_feature_local GEOMETRIC_SPECULAR_AA
            #pragma shader_feature_local PARALLAX
            #pragma shader_feature_local _ EMISSIONMAP EMISSION_BASE
            #pragma shader_feature_local _ BAKERY_SH BAKERY_RNM

            #include "PassCGI.cginc"
            ENDCG
        }


        Pass
        {
            Name "FWDADD"
            Tags { "LightMode"="ForwardAdd" }
            Fog { Color (0,0,0,0) }
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
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #pragma shader_feature_local _ CUTOUT FADE TRANSPARENT A2C_SHARPENED
            #pragma shader_feature_local MASKMAP
            #pragma shader_feature_local _ DETAILMAP DETAILMAP_UV1
            #pragma shader_feature_local NORMALMAP
            #pragma shader_feature_local PARALLAX
            #pragma shader_feature_local SPECULAR_HIGHLIGHTS

            #include "PassCGI.cginc"
            ENDCG
        }


        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            AlphaToMask Off
            ZWrite On
            Cull [_Cull]
            ZTest LEqual

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

            #pragma shader_feature_local _ CUTOUT FADE TRANSPARENT A2C_SHARPENED


            #include "PassCGI.cginc"
            ENDCG
        }
    }

    FallBack "Mobile/Unlit (Supports Lightmap)"
    CustomEditor "z3y.LitUI"
}
