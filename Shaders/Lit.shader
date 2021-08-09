Shader " Lit"
{

    Properties
    {
        
        [HideInInspector] shader_is_using_thry_editor("", Float)=1
        [HideInInspector] shader_master_label ("Lit v0.0.4", Float) = 0
        [HideInInspector] _ForgotToLockMaterial (";;YOU_FORGOT_TO_LOCK_THIS_MATERIAL;", Int) = 1
        [ThryShaderOptimizerLockButton] _ShaderOptimizerEnabled ("", Float) = 0
        

        [HideInInspector] m_Main ("Surface Inputs", Float) = 1
        
        //rendering preset from poiyomi
        [ThryWideEnum(Opaque, 0, Cutout, 1, Fade, 2, Transparent, 3, Additive, 4, SoftAdditive, 5, Multiplicative, 6, 2x Multiplicative, 7)]_Mode("Rendering Mode--{on_value_actions:[ 
            {value:0,actions:[{type:SET_PROPERTY,data:render_queue=2000}, {type:SET_PROPERTY,data:render_type=Opaque},            {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=0},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=1}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:1,actions:[{type:SET_PROPERTY,data:render_queue=2450}, {type:SET_PROPERTY,data:render_type=TransparentCutout}, {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=.5}, {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=0},                                            {type:SET_PROPERTY,data:_ZWrite=1}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:2,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=5}, {type:SET_PROPERTY,data:_DstBlend=10}, {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:3,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=10}, {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=1}]},
            {value:4,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=1},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:5,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},        {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=4}, {type:SET_PROPERTY,data:_DstBlend=1},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:6,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=2}, {type:SET_PROPERTY,data:_DstBlend=0},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:7,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=2}, {type:SET_PROPERTY,data:_DstBlend=3},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]}
        }]}]}", Int) = 0
        

        _Cutoff ("Alpha Cuttoff--{condition_show:{type:PROPERTY_BOOL,data:_Mode==1}}", Range(0, 1.001)) = 0.5
        [Enum(Off, 0, On, 1)] _AlphaToMask ("Alpha To Coverage--{condition_show:{type:PROPERTY_BOOL,data:_Mode==1}}", Float) = 0


        _MainTex ("Base Map --{reference_property:_Color,reference_properties:[_MainTexUV,_Saturation, _EnableVertexColor]}", 2D) = "white" {}
        [HideInInspector] _Color ("Color", Color) = (1,1,1,1)
        [HideInInspector] _Saturation ("Saturation", Range(-1,1)) = 0
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _MainTexUV ("UV", Int) = 0
        
        [HideInInspector] [ToggleUI] _EnableVertexColor ("Vertex Colors Mulitply", Float) = 0
               
                
        
        
        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Occlusion ("Occlusion", Range(0,1)) = 0

        
        [HideInInspector] [ToggleUI] _EnablePackedMap ("Enable Roughness Map ", Float) = 0
        [sRGBWarning] _MetallicGlossMap ("Mask Map--{tooltip:Metallic(R) Occlusion(G) Detail Mask(B) Smoothness(A),reference_properties:[_MetallicGlossMapUV,_EnableVertexColorMask],condition_show:{type:PROPERTY_BOOL,data:_EnablePackedMode==1},on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnablePackedMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnablePackedMap=1}]}]} ", 2D) = "white" {}
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _MetallicGlossMapUV ("UV", Int) = 0
        [HideInInspector] [ToggleUI] _EnableVertexColorMask ("Vertex Colors Mulitply", Float) = 0


        [HideInInspector] [ToggleUI] _EnableRoughnessMap ("Enable Roughness Map", Float) = 0
        [sRGBWarning] _SmoothnessMap ("Smoothness Map--{condition_show:{type:PROPERTY_BOOL,data:_EnablePackedMode==0},reference_properties:[_SmoothnessMapUV,_GlossinessInvert],on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableRoughnessMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableRoughnessMap=1}]}]} ", 2D) = "white" {}
        
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _SmoothnessMapUV ("UV", Int) = 0
        [HideInInspector] [ToggleUI] _GlossinessInvert ("Invert", Float) = 0

        
        [HideInInspector] [ToggleUI] _EnableMetallicMap ("Enable Metallic Map", Float) = 0
        [sRGBWarning] _MetallicMap ("Metallic Map--{condition_show:{type:PROPERTY_BOOL,data:_EnablePackedMode==0},reference_properties:[_MetallicMapUV],on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableMetallicMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableMetallicMap=1}]}]} ", 2D) = "white" {}
        
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _MetallicMapUV ("UV", Int) = 0
        

        

        [HideInInspector] [ToggleUI] _EnableOcclusion("Occlusion", Float) = 0
        [sRGBWarning] _OcclusionMap ("Occlusion Map--{condition_show:{type:PROPERTY_BOOL,data:_EnablePackedMode==0},reference_properties:[_OcclusionMapUV],on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableOcclusion=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableOcclusion=1}]}]} ", 2D) = "white" {}
        
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _OcclusionMapUV ("UV", Int) = 0

        [HideInInspector] [ToggleUI] _EnableNormalMap ("Enable Normal Map", Float) = 0
        [Normal] _BumpMap ("Normal Map--{reference_property:_BumpScale,reference_properties:[_BumpMapUV,_NormalMapOrientation],on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnableNormalMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnableNormalMap=1}]}]} ", 2D) = "bump" {}
        [HideInInspector] _BumpScale ("Bump Scale", Range(0,10)) = 1
        [HideInInspector] [Enum(OpenGL, 0, Direct3D, 1)] _NormalMapOrientation ("Orientation", Int) = 0
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _BumpMapUV ("UV", Int) = 0

        [ToggleUI] _EnableEmission ("Emission", Float) = 0
        _EmissionMap ("Emission Map--{condition_show:{type:PROPERTY_BOOL,data:_EnableEmission==1},reference_property:_EmissionColor,reference_properties:[_EmissionMapUV]}", 2D) = "white" {}
        [HideInInspector] [HDR] _EmissionColor ("Color", Color) = (0,0,0)
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _EmissionMapUV ("UV", Int) = 0

        

        
        [HideInInspector] m_Specular ("Reflections And Specular Highlights", Float) = 0
        [Enum(Default, 0, Get From Probes, 1)] _GetDominantLight ("Mode", Int) = 0
        _FresnelColor ("Fresnel", Color) = (1,1,1,1)
        _Reflectance ("Reflectance", Range(0,1)) = 0.45
        _AngularGlossiness ("Angular Glossiness", Range(0, 1)) = 0

        [Toggle(ENABLE_GSAA)] _GSAA ("Geometric Specular AA", Float) = 0

        [PowerSlider(3)] _specularAntiAliasingVariance ("Variance--{condition_show:{type:PROPERTY_BOOL,data:_GSAA==1}}", Range(0.0, 1.0)) = 0.15
        [PowerSlider(3)] _specularAntiAliasingThreshold ("Threshold--{condition_show:{type:PROPERTY_BOOL,data:_GSAA==1}}", Range(0.0, 1.0)) = 0.1
        
        [Space(10)]
        [Toggle(ENABLE_SPECULAR_HIGHLIGHTS)] _SpecularHighlights("Specular Highlights", Float) = 1
        [Toggle(ENABLE_REFLECTIONS)] _GlossyReflections("Reflections", Float) = 1


        
        
        
        




        

        


        
        [HideInInspector] m_BakedLight ("Baked Light", Float) = 0

        
        _LightmapMultiplier ("Multiplier", Range(0, 2)) = 1
        _SpecularOcclusion ("Specular Occlusion", Range(0, 1)) = 0

        [Toggle(ENABLE_BICUBIC_LIGHTMAP)] _BicubicLightmap ("Bicubic Lightmap Interpolation", Float) = 0
        [ToggleUI] _LightProbeMethod ("Non-linear Light Probe SH", Float) = 0

        

        [HideInInspector] m_RenderingOptions ("Advanced Options", Float) = 0

        [HideInInspector] m_start_blending ("Blending", Float) = 0
        [Enum(Thry.BlendOp)]_BlendOp ("RGB Blend Op", Int) = 0
        [Enum(Thry.BlendOp)]_BlendOpAlpha ("Alpha Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
        [HideInInspector] m_end_blending ("Blending", Float) = 0

        [HideInInspector] m_start_PP ("Post-Processing", Float) = 0
        [Enum(None, 0, ACES, 1)] _TonemappingMode ("Mode", Int) = 0
        _Contribution ("Contribution", Range(0, 1)) = 1
        [HideInInspector] m_end_PP ("", Float) = 0

        [Toggle(ENABLE_PACKED_MODE)] _EnablePackedMode ("Packed Mode", Float) = 1       

        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
 
        
        
        



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
    CustomEditor "Thry.ShaderEditor"
}