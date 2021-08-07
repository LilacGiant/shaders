Shader " Lit"
{

    Properties
    {
        _ShaderOptimizerEnabled ("", Int) = 0
        [Enum(Opaque, 0, Cutout, 1, Fade, 2, Transparent, 3)] _Mode ("Rendering Mode", Int) = 0
        

        _Cutoff ("Alpha Cuttoff", Range(0.001, 1)) = 0.5

        _MainTex ("Base Map", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Saturation ("Saturation", Range(-1,1)) = 0
        [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _MainTexUV ("UV", Int) = 0
        
        [ToggleUI] _EnableVertexColor ("Vertex Colors Mulitply", Float) = 0
               

        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Occlusion ("Occlusion", Range(0,1)) = 1

        
        _MetallicGlossMap ("Mask Map", 2D) = "white" {}
        [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _MetallicGlossMapUV ("UV", Int) = 0

        [ToggleUI] _EnableRoughnessMap ("Enable Roughness Map", Float) = 0
        _SmoothnessMap ("Smoothness Map", 2D) = "white" {}
        
        [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _SmoothnessMapUV ("UV", Int) = 0
        [ToggleUI] _GlossinessInvert ("Invert", Float) = 0

        
        [ToggleUI] _EnableMetallicMap ("Enable Metallic Map", Float) = 0
        _MetallicMap ("Metallic Map", 2D) = "white" {}
        
        [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _MetallicMapUV ("UV", Int) = 0
        

        

        [ToggleUI] _EnableOcclusion("Occlusion", Float) = 0
        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
        
        [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _OcclusionMapUV ("UV", Int) = 0

        [ToggleUI] _EnableNormalMap ("Enable Normal Map", Float) = 0
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Range(0,10)) = 1
        [Enum(OpenGL, 0, Direct3D, 1)] _NormalMapOrientation ("Orientation", Int) = 0
        [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _BumpMapUV ("UV", Int) = 0

        

        

        [Toggle(ENABLE_SPECULAR_HIGHLIGHTS)] _SpecularHighlights("Specular Highlights", Float) = 1
        [Enum(Realtime Light, 0,Light Probes, 1)] _GetDominantLight ("Mode", Int) = 0

        [Toggle(ENABLE_REFLECTIONS)] _GlossyReflections("Reflections", Float) = 1
        _Reflectance ("Reflectance", Range(0,1)) = 0.5
        _AngularGlossiness ("Angular Glossiness", Range(0, 1)) = 0
        //_ExposureOcclusion ("Exposure Occlusion Sensitivity", Range(0, 1)) = 0
        
        _FresnelColor ("Fresnel", Color) = (1,1,1,1)
        

        [Toggle(ENABLE_GSAA)] _GSAA("GSAA", Float) = 0
        [PowerSlider(3)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.15
        [PowerSlider(3)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1

        




        [ToggleUI] _EnableEmission ("Emission", Float) = 0
        _EmissionMap ("Emission Map", 2D) = "white" {}
        [HDR] _EmissionColor ("Color", Color) = (0,0,0)
        [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _EmissionMapUV ("UV", Int) = 0

        

        


        

        [Toggle(ENABLE_BICUBIC_LIGHTMAP)] _BicubicLightmap ("Bicubic Lightmap Interpolation", Float) = 0
        _LightmapMultiplier ("Multiplier", Range(0, 2)) = 1
        _SpecularOcclusion ("Specular Occlusion", Range(0, 1)) = 0

        

        [ToggleUI] _LightProbeMethod ("Non-linear Light Probe SH", Float) = 0



        [Enum(None, 0, ACES, 1)] _TonemappingMode ("Mode", Int) = 0
        _Contribution ("Contribution", Range(0, 1)) = 1
       


        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOp ("RGB Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOpAlpha ("Alpha Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0


        [Toggle(ENABLE_PACKED_MODE)] _EnablePackedMode ("Packed Mode", Float) = 1       

        [Enum(Off, 0, On, 1)] _AlphaToMask ("Alpha To Coverage", Int) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Int) = 2
        
        
        



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

            #pragma shader_feature_local ENABLE_GSAA
            #pragma shader_feature_local ENABLE_SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local ENABLE_REFLECTIONS
            #pragma shader_feature_local ENABLE_PACKED_MODE
            #pragma shader_feature_local ENABLE_BICUBIC_LIGHTMAP


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

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers gles3
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing

            #pragma shader_feature_local ENABLE_SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local ENABLE_REFLECTIONS
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
            ZWrite [_ZWrite]
            Cull [_Cull]
            ZTest [_ZTest]

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

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma only_renderers gles3
            #pragma multi_compile_fwdbase
            #pragma multi_compile_instancing

            #pragma shader_feature_local ENABLE_SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local ENABLE_REFLECTIONS
            #pragma shader_feature_local ENABLE_PACKED_MODE

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

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma only_renderers gles3
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_instancing

            #pragma shader_feature_local ENABLE_SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local ENABLE_REFLECTIONS
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
            ZWrite [_ZWrite]
            Cull [_Cull]
            ZTest [_ZTest]

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