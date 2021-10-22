Shader "z3y/new lit"
{
    Properties
    {
        wAg6H2wQzc7UbxaL ("Is Locked", Int) = 0

        [KeywordEnum(Metallic, Specular, Triplanar, Unpacked)] _Workflow ("Workflow", Int) = 0
        [KeywordEnum(Opaque, Cutout, Fade, Transparent, A2C, A2C Sharpened)] _Mode ("Rendering Mode", Int) = 0
        _Cutoff ("Alpha Cuttoff", Range(0, 1)) = 0.5


        _MainTex ("Base Map", 2D) = "white" {}
            [Enum(UV 0, 0, UV 1, 1, UV 2, 2, Stochastic, 4)] _MainTex_UV ("UV Type", Int) = 0
            _Color ("Base Color", Color) = (1,1,1,1)

        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Occlusion ("Occlusion", Range(0,1)) = 0

        _MetallicGlossMap ("Mask Map:Metallic(R), Occlusion(G), Detail Mask(B), Smoothness(A)", 2D) = "white" {}
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3, Stochastic, 4)] _MetallicGlossMap_UV ("UV Type", Int) = 0

        _SmoothnessMap ("Smoothness Map", 2D) = "white" {}
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3, Stochastic, 4)]  _SmoothnessMap_UV ("UV Type", Int) = 0
            [ToggleUI] _GlossinessInvert ("Invert Smoothness", Float) = 0

        _MetallicMap ("Metallic Map", 2D) = "white" {}
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3, Stochastic, 4)]  _MetallicMap_UV ("UV Type", Int) = 0

        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3, Stochastic, 4)]  _OcclusionMap_UV ("UV Type", Int) = 0


        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
            _BumpScale ("Bump Scale", Range(0,10)) = 0
            [Enum(OpenGL, 0, Direct3D, 1)] _NormalMapOrientation ("Orientation", Int) = 0
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3, Stochastic, 4)] _BumpMap_UV ("UV Type", Int) = 0
            [ToggleUI] _HemiOctahedron ("Hemi Octahedron", Int) = 0


        [Toggle(SPECULAR_HIGHLIGHTS)] _SpecularHighlights("Specular Highlights", Float) = 1
        [Toggle(REFLECTIONS)] _GlossyReflections("Reflections", Float) = 1
            // _FresnelColor ("Tint", Color) = (1,1,1,1)
            _FresnelIntensity ("Fresnel Intensity", Range(0,1)) = 1
            _Reflectance ("Reflectance", Range(0,1)) = 0.5
            _SpecularOcclusion ("Specular Occlusion", Range(0,1)) = 0



        [Toggle(BICUBIC_LIGHTMAP)] _BicubicLightmap ("Bicubic Lightmap", Int) = 0
        [ToggleUI] _InvertSmoothness ("Invert Smoothness", Int) = 0

        [ToggleUI] _GSAA ("Geometric Specular AA", Int) = 0
            [PowerSlider(3)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.15
            [PowerSlider(3)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1

        [Toggle(EMISSION)] _EnableEmission ("Emission", Int) = 0
            _EmissionMap ("Emission Map", 2D) = "white" {}
            [ToggleUI] _EmissionMultBase ("Multiply Base", Int) = 0
            [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3, Stochastic, 4)]  _EmissionMap_UV ("UV Type", Int) = 0
        

        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOpAlpha ("Blend Op Alpha", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
        [Enum(Off, 0, On, 1)] _AlphaToMask ("Alpha To Coverage", Int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
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
            #pragma exclude_renderers gles3
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            // #pragma multi_compile _ VERTEXLIGHT_ON
            // #pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma shader_feature_local _ _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT _MODE_A2C _MODE_A2C_SHARPENED
            #pragma shader_feature_local _ _WORKFLOW_SPECULAR _WORKFLOW_TRIPLANAR _WORKFLOW_UNPACKED
            #pragma shader_feature_local BICUBIC_LIGHTMAP
            #pragma shader_feature_local SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local REFLECTIONS
            #pragma shader_feature_local EMISSION


            #include "PassCGI.cginc"
            ENDCG
        }

        Pass
        {
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
            #pragma exclude_renderers gles3
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            // #pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma shader_feature_local _ _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT _MODE_A2C _MODE_A2C_SHARPENED
            #pragma shader_feature_local _ _WORKFLOW_SPECULAR _WORKFLOW_TRIPLANAR _WORKFLOW_UNPACKED
            #pragma shader_feature_local SPECULAR_HIGHLIGHTS


            #include "PassCGI.cginc"
            ENDCG
        }


        Pass
        {
            Tags { "LightMode"="ShadowCaster" }
            AlphaToMask Off
            ZWrite On
            Cull [_Cull]
            ZTest LEqual

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma exclude_renderers gles3
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            // #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2

            #pragma shader_feature_local _ _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT _MODE_A2C _MODE_A2C_SHARPENED
            #pragma shader_feature_local _ _WORKFLOW_SPECULAR _WORKFLOW_TRIPLANAR _WORKFLOW_UNPACKED


            #include "PassCGI.cginc"
            ENDCG
        }
    }
    CustomEditor "z3y.LitUI"
    FallBack "Mobile/Lit Quest"
}
