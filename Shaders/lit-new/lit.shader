Shader "z3y/new lit"
{
    Properties
    {
        wAg6H2wQzc7UbxaL ("Is Locked", Int) = 0

        [KeywordEnum(Metallic, Specular, Anisotropic, Triplanar, Unpacked)] _Workflow ("Workflow", Int) = 0
        [KeywordEnum(Opaque, Cutout, Fade, Transparent, A2C, A2C Sharpened)] _Mode ("Rendering Mode", Int) = 0


        _MainTex ("Base Map", 2D) = "white" {}
            [Enum(UV 0, 0, UV 1, 1, UV 2, 2, Stochastic, 4)] _MainTex_UV ("UV Type", Int) = 0
            _Color ("Base Color", Color) = (1,1,1,1)

        [Toggle(BICUBIC_LIGHTMAP)] _BicubicLightmap ("Bicubic Lightmap", Float) = 0


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

            #pragma shader_feature_local _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT _MODE_A2C _MODE_A2C_SHARPENED
            #pragma shader_feature_local _WORKFLOW_SPECULAR _WORKFLOW_ANISOTROPIC _WORKFLOW_TRIPLANAR _WORKFLOW_UNPACKED
            #pragma shader_feature_local BICUBIC_LIGHTMAP


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

            #pragma shader_feature_local _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT _MODE_A2C _MODE_A2C_SHARPENED
            #pragma shader_feature_local _WORKFLOW_SPECULAR _WORKFLOW_ANISOTROPIC _WORKFLOW_TRIPLANAR _WORKFLOW_UNPACKED


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

            #pragma shader_feature_local _MODE_CUTOUT _MODE_FADE _MODE_TRANSPARENT _MODE_A2C _MODE_A2C_SHARPENED
            #pragma shader_feature_local _WORKFLOW_SPECULAR _WORKFLOW_ANISOTROPIC _WORKFLOW_TRIPLANAR _WORKFLOW_UNPACKED


            #include "PassCGI.cginc"
            ENDCG
        }
    }
    CustomEditor "z3y.LitUI"
    FallBack "Mobile/Lit Quest"
}
