Shader " Lit"
{

    Properties
    {
        _ShaderOptimizerEnabled ("", Float) = 0

        [Enum(Opaque, 0, Cutout, 1, Fade, 2, Transparent, 3)] _Mode("Rendering Mode", Int) = 0
        
        [Enum(Off, 0, On, 1, Sharpened, 2)] _AlphaToMask ("Alpha To Coverage", Float) = 0
        _Cutoff ("Alpha Cuttoff", Range(0.001, 1)) = 0.5

        _MainTex ("Base Map", 2D) = "white" {}
        _MainTex_STAnimated("_MainTex_ST", Int) = 1
        _Color ("Base Color", Color) = (1,1,1,1)
        _Saturation ("Saturation", Range(-1,1)) = 0
        [Enum(UV0, 0, UV1, 1, UV2, 2)] _MainTexUV ("UV", Int) = 0
        
        [ToggleUI] _EnableVertexColor ("Vertex Colors Mulitply Base", Float) = 0
               
        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Occlusion ("Occlusion", Range(0,1)) = 0


        _MetallicGlossMap ("Mask Map:Metallic(R), Occlusion(G), Detail Mask(B), Smoothness(A)", 2D) = "white" {}
        [Enum(UV0, 0, UV1, 1, UV2, 2)] _MetallicGlossMapUV ("UV", Int) = 0


        _SmoothnessMap ("Smoothness Map", 2D) = "white" {}
        [Enum(UV0, 0, UV1, 1, UV2, 2)] _SmoothnessMapUV ("UV", Int) = 0
        [ToggleUI] _GlossinessInvert ("Invert Smoothness", Float) = 0

        _MetallicMap ("Metallic Map", 2D) = "white" {}
        [Enum(UV0, 0, UV1, 1, UV2, 2)] _MetallicMapUV ("UV", Int) = 0

        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
        [Enum(UV0, 0, UV1, 1, UV2, 2)] _OcclusionMapUV ("UV", Int) = 0

        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Range(0,10)) = 0
        [Enum(OpenGL, 0, Direct3D, 1)] _NormalMapOrientation ("Orientation", Int) = 0
        [Enum(UV0, 0, UV1, 1, UV2, 2)] _BumpMapUV ("UV", Int) = 0

        [ToggleUI] _EnableEmission ("Emission", Float) = 0
        _EmissionMap ("Emission Map", 2D) = "white" {}
        [HDR] _EmissionColor ("Emission Color", Color) = (0,0,0)
        [Enum(UV0, 0, UV1, 1, UV2, 2)] _EmissionMapUV ("UV", Int) = 0

        
        [Enum(Default, 0, Light Probes, 1)] _GetDominantLight ("Dominant Light", Int) = 0
        _FresnelColor ("Sheen Color", Color) = (1,1,1,1)
        _Reflectance ("Reflectance", Range(0,1)) = 0.5
        _Anisotropy ("Anisotropy", Range(-1,1)) = 0


        [Toggle(ENABLE_SPECULAR_HIGHLIGHTS)] _SpecularHighlights("Specular Highlights", Float) = 1
        [Toggle(ENABLE_REFLECTIONS)] _GlossyReflections("Reflections", Float) = 1


        [Toggle(ENABLE_GSAA)] _GSAA ("Geometric Specular AA", Float) = 0
        [PowerSlider(3)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.15
        [PowerSlider(3)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1
        
        
        _LightmapMultiplier ("Lightmap Multiplier", Range(0, 2)) = 1
        _SpecularOcclusion ("Lightmap Specular Occlusion", Range(0, 1)) = 0

        [Toggle(ENABLE_BICUBIC_LIGHTMAP)] _BicubicLightmap ("Bicubic Lightmap Interpolation", Float) = 0
        [ToggleUI] _LightProbeMethod ("Non-linear Light Probe SH", Float) = 0


        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("RGB Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOpAlpha ("Alpha Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0


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

        [Toggle(ENABLE_AUDIOLINK)] _EnableAudioLink ("Audio Link", Float) = 0
        _AudioTexture ("Audio Link Render Texture", 2D) = "black" {}
        _ALSmoothing ("Audio Link Smoothing", Range(0, 1)) = 0.5

        [Enum(Bass, 0, Low Mids, 1, High Mids, 2, Treble, 3)] _ALEmissionBand ("Audio Link Emission Band", Int) = 0
        [Enum(Disabled, 0, Gradient, 1, Path, 2, Intensity, 3)] _ALEmissionType ("Audio Link Emission Type", Int) = 0
        _ALEmissionMap ("Audio Link Emission Path & Mask: Path(G), Mask(A)", 2D) = "white" {}

        [Toggle(BAKERY_SH)] _BAKERY_SH ("Enable SH", Float) = 0
        [Toggle(BAKERY_SHNONLINEAR)] _BAKERY_SHNONLINEAR ("SH non-linear mode", Float) = 1
        [Toggle(BAKERY_RNM)] _BAKERY_RNM ("Enable RNM", Float) = 0
        [Toggle(BAKERY_LMSPEC)] _BAKERY_LMSPEC ("Enable Lightmap Specular", Float) = 0
        
        [Enum(BAKERYMODE_DEFAULT, 0, BAKERYMODE_VERTEXLM, 1, BAKERYMODE_RNM, 2, BAKERYMODE_SH, 3)] bakeryLightmapMode ("bakeryLightmapMode", Float) = 0
        _RNM0("RNM0", 2D) = "black" {}
        _RNM1("RNM1", 2D) = "black" {}
        _RNM2("RNM2", 2D) = "black" {}

        [Toggle(LOD_FADE_CROSSFADE)] _LodCrossFade ("Dithered LOD Cross-Fade", Float) = 0
        [ToggleUI] _FlatShading ("Flat Shading", Float) = 0


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
            #pragma shader_feature_local ENABLE_PARALLAX
            #pragma shader_feature_local ENABLE_REFRACTION
            #pragma shader_feature_local ENABLE_AUDIOLINK
            #pragma shader_feature_local BAKERY_SHNONLINEAR
            #pragma shader_feature_local LOD_FADE_CROSSFADE

            #pragma shader_feature_local BAKERY_SH
            #pragma shader_feature_local BAKERY_RNM
            #pragma shader_feature_local BAKERY_LMSPEC


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
            #pragma shader_feature_local LOD_FADE_CROSSFADE


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

            #pragma shader_feature_local LOD_FADE_CROSSFADE
            
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
            #pragma shader_feature_local ENABLE_AUDIOLINK


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