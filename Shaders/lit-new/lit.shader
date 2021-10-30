Shader "z3y/lit"
{
    Properties
    {
        wAg6H2wQzc7UbxaL ("Is Locked", Int) = 0

        [Toggle(_WORKFLOW_UNPACKED)] _Workflow ("Unpacked Mask", Int) = 0
        [KeywordEnum(Opaque, Cutout, Fade, Transparent)] _Mode ("Rendering Mode", Int) = 0
        _Cutoff ("Alpha Cuttoff", Range(0, 1)) = 0.5
        _MipScale ("Mip Scale", Range(0, 1)) = 0.25

        [Toggle(TEXTUREARRAY)] _EnableTextureArray ("Texture Arrays", Float) = 0
        [Toggle(TEXTUREARRAYINSTANCED)] _EnableTextureArrayInstancing ("Instanced Array Index", Float) = 0
        _TextureIndex ("Instance Index", Int) = 0

        _TextureIndexAnimated("", Int) = 1

        _MainTex ("Base Map", 2D) = "white" {}
        _MainTexArray ("Base Map Array", 2DArray) = "white" {}
            [Enum(UV 0, 0, UV 1, 1, UV 2, 2)] _MainTex_UV ("UV Type", Int) = 0
            _Color ("Base Color", Color) = (1,1,1,1)
            _Saturation ("Saturation", Range(-1,1)) = 0


        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Occlusion ("Occlusion", Range(0,1)) = 0

        _MetallicGlossMap ("Mask Map:Metallic(R), Occlusion(G), Detail Mask(B), Smoothness(A)", 2D) = "white" {}
        [Toggle(TEXTUREARRAYMASK)] _EnableTextureArrayMask ("Mask Map Array", Float) = 0
        _MetallicGlossMapArray ("Mask Map Array:Metallic(R), Occlusion(G), Detail Mask(B), Smoothness(A)", 2DArray) = "white" {}
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3)] _MetallicGlossMap_UV ("UV Type", Int) = 0

        _SmoothnessMap ("Smoothness Map", 2D) = "white" {}
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3)]  _SmoothnessMap_UV ("UV Type", Int) = 0
            [ToggleUI] _GlossinessInvert ("Invert Texture", Float) = 0

        _MetallicMap ("Metallic Map", 2D) = "white" {}
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3)]  _MetallicMap_UV ("UV Type", Int) = 0

        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3)]  _OcclusionMap_UV ("UV Type", Int) = 0


        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpMapArray ("Normal Map Array", 2DArray) = "bump" {}
            [Toggle(TEXTUREARRAYBUMP)] _EnableTextureArrayBump ("Normal Map Array", Float) = 0
            _BumpScale ("Bump Scale", Range(0,10)) = 0
            [Enum(OpenGL, 0, Direct3D, 1)] _NormalMapOrientation ("Orientation", Int) = 0
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3)] _BumpMap_UV ("UV Type", Int) = 0
            [ToggleUI] _HemiOctahedron ("Hemi Octahedron", Int) = 0


        [Toggle(SPECULAR_HIGHLIGHTS)] _SpecularHighlights("Specular Highlights", Float) = 1
        [Toggle(REFLECTIONS)] _GlossyReflections("Reflections", Float) = 1
            _FresnelIntensity ("Fresnel Intensity", Range(0,1)) = 1
            _Reflectance ("Reflectance", Range(0,1)) = 0.5
            _SpecularOcclusion ("Specular Occlusion", Range(0,1)) = 0
            _FresnelColor ("Tint", Color) = (1,1,1)


        [Toggle(BICUBIC_LIGHTMAP)] _BicubicLightmap ("Bicubic Lightmap", Int) = 0

        [ToggleUI] _GSAA ("Geometric Specular AA", Int) = 0
            [PowerSlider(2)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.15
            [PowerSlider(2)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1

        [Toggle(EMISSION)] _EnableEmission ("Emission", Int) = 0
            _EmissionMap ("Emission Map", 2D) = "white" {}
            [ToggleUI] _EmissionMultBase ("Multiply Base", Int) = 0
            [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3)]  _EmissionMap_UV ("UV Type", Int) = 0

        _DetailMap ("Detail Map:Desaturated Albedo(R), Normal Y(G), Smoothness(B), Normal X(A)", 2D) = "linearGrey" {}
            [Enum(UV 0 Locked, 0, UV 1, 1, UV 2, 2, UV 0 Unlocked, 3)]  _DetailMap_UV ("UV Type", Int) = 0
            _DetailAlbedoScale ("Albedo Scale", Range(0.0, 2.0)) = 0
            _DetailNormalScale ("Normal Scale", Range(0.0, 2.0)) = 0
            _DetailSmoothnessScale ("Smoothness Scale", Range(0.0, 2.0)) = 0

        [Toggle(PARALLAX)] _EnableParallax ("Parallax", Int) = 0
            _Parallax ("Height Scale", Range (0, 0.2)) = 0.02
            _ParallaxMap ("Height Map", 2D) = "white" {}
            [IntRange] _ParallaxSteps ("Parallax Steps", Range(1,50)) = 25
            _ParallaxOffset ("Parallax Offset", Range(-1, 1)) = 0


        [Toggle(NONLINEAR_LIGHTPROBESH)] _NonLinearLightProbeSH ("Non-linear Light Probe SH", Int) = 1
        [Toggle(BAKEDSPECULAR)] _BakedSpecular ("Baked Specular Highlights ", Int) = 0

        [Toggle(ANISOTROPY)] _EnableAnisotropy ("Anisotropy", Int) = 0
            _Anisotropy ("Anisotropy", Range(-1,1)) = 0
            _AnisotropyMap ("Anisotropy Direction Map:Bitangent(R), Tangent(G)", 2D) = "white" {}
        

        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOpAlpha ("Blend Op Alpha", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
        [Enum(Off, 0, On, 1)] _AlphaToMask ("Alpha To Coverage", Int) = 0

        // optimizer toggles
        [ToggleUI] VertexLights("Allow Vertex Lights", Float) = 0

        // unlocked properties
        _MetallicAnimated("", Float) = 1
        _GlossinessAnimated("", Float) = 1
        _OcclusionAnimated("", Float) = 1
        _BumpScaleAnimated("", Float) = 1
        _ReflectanceAnimated("", Float) = 1
        _ColorAnimated("", Float) = 1

    }
    

    SubShader
    {
        CGINCLUDE
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        #pragma exclude_renderers gles3
        #pragma fragmentoption ARB_precision_hint_fastest
        
        #pragma shader_feature_local _ _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT
        #pragma shader_feature_local _WORKFLOW_UNPACKED
        #pragma shader_feature_local BICUBIC_LIGHTMAP
        #pragma shader_feature_local SPECULAR_HIGHLIGHTS
        #pragma shader_feature_local REFLECTIONS
        #pragma shader_feature_local EMISSION
        #pragma shader_feature_local PARALLAX
        #pragma shader_feature_local NONLINEAR_LIGHTPROBESH
        #pragma shader_feature_local BAKEDSPECULAR
        #pragma shader_feature_local ANISOTROPY
        #pragma shader_feature_local TEXTUREARRAYINSTANCED
        #pragma shader_feature_local TEXTUREARRAY
        #pragma shader_feature_local TEXTUREARRAYMASK
        #pragma shader_feature_local TEXTUREARRAYBUMP

        ENDCG

        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Name "FORWARDBASE"
            Tags { "LightMode"="ForwardBase" }
            ZWrite [_ZWrite]
            Cull [_Cull]
            ZTest [_ZTest]
            AlphaToMask [_AlphaToMask]
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend [_SrcBlend] [_DstBlend]

            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            //CommentIfZero_VertexLights
            #pragma multi_compile _ VERTEXLIGHT_ON
            //CommentIfZero_VertexLights

            // #pragma multi_compile _ LOD_FADE_CROSSFADE

            #define NEED_TANGENT_BITANGENT
            #define NEED_WORLD_POS
            #define NEED_WORLD_NORMAL

            #include "PassCGI.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARDADD"
            Tags { "LightMode"="ForwardAdd" }
            Fog { Color (0,0,0,0) }
            ZWrite Off
            BlendOp [_BlendOp], [_BlendOpAlpha]
            Blend One One
            Cull [_Cull]
            ZTest [_ZTest]
            AlphaToMask [_AlphaToMask]

            CGPROGRAM
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            // #pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma skip_variants BICUBIC_LIGHTMAP REFLECTIONS EMISSION BAKEDSPECULAR
            #undef BICUBIC_LIGHTMAP
            #undef REFLECTIONS
            #undef EMISSION
            #undef BAKEDSPECULAR


            #define NEED_TANGENT_BITANGENT
            #define NEED_WORLD_POS
            #define NEED_WORLD_NORMAL
            
            #include "PassCGI.cginc"
            ENDCG
        }


        Pass
        {
            Name "SHADOWCASTER"
            Tags { "LightMode"="ShadowCaster" }
            AlphaToMask Off
            ZWrite On
            Cull [_Cull]
            ZTest LEqual

            CGPROGRAM
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            // #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma skip_variants REFLECTIONS EMISSION BICUBIC_LIGHTMAP PARALLAX BAKEDSPECULAR ANISOTROPY NONLINEAR_LIGHTPROBESH SPECULAR_HIGHLIGHTS _WORKFLOW_UNPACKED TEXTUREARRAYMASK TEXTUREARRAYBUMP
            #undef REFLECTIONS
            #undef EMISSION
            #undef BICUBIC_LIGHTMAP
            #undef PARALLAX
            #undef BAKEDSPECULAR
            #undef ANISOTROPY
            #undef NONLINEAR_LIGHTPROBESH
            #undef SPECULAR_HIGHLIGHTS
            #undef _WORKFLOW_UNPACKED
            #undef TEXTUREARRAYMASK
            #undef TEXTUREARRAYBUMP

            #include "PassCGI.cginc"
            ENDCG
        }

        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }
            Cull Off

            CGPROGRAM
            #pragma shader_feature EDITOR_VISUALIZATION

            #pragma skip_variants BICUBIC_LIGHTMAP SPECULAR_HIGHLIGHTS REFLECTIONS PARALLAX NONLINEAR_LIGHTPROBESH BAKEDSPECULAR ANISOTROPY TEXTUREARRAYMASK TEXTUREARRAYBUMP
            #undef BICUBIC_LIGHTMAP
            #undef SPECULAR_HIGHLIGHTS
            #undef REFLECTIONS
            #undef PARALLAX
            #undef NONLINEAR_LIGHTPROBESH
            #undef BAKEDSPECULAR
            #undef ANISOTROPY
            #undef TEXTUREARRAYMASK
            #undef TEXTUREARRAYBUMP

            #define NEED_TANGENT_BITANGENT
            #define NEED_WORLD_POS
            #define NEED_WORLD_NORMAL

            #include "PassCGI.cginc"
            ENDCG
        }
    }
    CustomEditor "z3y.LitUI"
    FallBack "Mobile/Lit Quest"
}
