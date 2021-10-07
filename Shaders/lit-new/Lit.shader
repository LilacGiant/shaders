Shader "Custom/Lit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)

        [Space(10)]
        [Toggle(MASKMAP)] _EnableMaskMap ("_EnableMaskMap", Float) = 0
        _MetallicGlossMap ("Mask Map:Metallic(R), Occlusion(G), Detail Mask(B), Smoothness(A)", 2D) = "white" {}
        [Gamma] _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Occlusion ("Occlusion", Range(0,1)) = 0

        [Space(10)]
        [Toggle(NORMALMAP)] _EnableNormalMap ("_EnableNormalMap", Float) = 0
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Range(0,10)) = 1



        [Space(10)]
        [Toggle(SPECULAR_HIGHLIGHTS)] _SpecularHighlights ("Specular Highlights", Float) = 1
        [Toggle(REFLECTIONS)] _GlossyReflections ("Reflections", Float) = 1
        _Reflectance ("Reflectance", Range(0,1)) = 0.5
        _FresnelColor ("Base Color", Color) = (1,1,1,1)

        [Space(10)]
        [Toggle(GEOMETRIC_SPECULAR_AA)] _GSAA ("Geometric Specular AA", Int) = 0
        [PowerSlider(3)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.15
        [PowerSlider(3)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1

        [Space(10)]
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

            #pragma shader_feature_local MASKMAP
            #pragma shader_feature_local NORMALMAP
            #pragma shader_feature_local SPECULAR_HIGHLIGHTS
            #pragma shader_feature_local REFLECTIONS
            #pragma shader_feature_local GEOMETRIC_SPECULAR_AA

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

            #pragma shader_feature_local MASKMAP
            #pragma shader_feature_local NORMALMAP
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

            #include "PassCGI.cginc"
            ENDCG
        }
    }
}
