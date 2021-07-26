Shader " Lit"
{

    Properties
    {
        
        [HideInInspector] shader_is_using_thry_editor("", Float)=1
        [HideInInspector] _ForgotToLockMaterial (";;YOU_FORGOT_TO_LOCK_THIS_MATERIAL;", Int) = 1
        [ThryShaderOptimizerLockButton] _ShaderOptimizerEnabled ("", Float) = 0
        

        [HideInInspector] m_Main ("Surface Inputs", Float) = 1
        
        //rendering preset from poiyomi
[ThryWideEnum(Opaque, 0, Cutout, 1, Fade, 2, Transparent, 3, Additive, 4, Soft Additive, 5, Multiplicative, 6, 2x Multiplicative, 7)]_Mode("Rendering Mode--{on_value_actions:[ 
            {value:0,actions:[{type:SET_PROPERTY,data:render_queue=2000}, {type:SET_PROPERTY,data:render_type=Opaque},            {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=0},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=1}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:1,actions:[{type:SET_PROPERTY,data:render_queue=2450}, {type:SET_PROPERTY,data:render_type=TransparentCutout}, {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=.5}, {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=0},  {type:SET_PROPERTY,data:_AlphaToMask=1},  {type:SET_PROPERTY,data:_ZWrite=1}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:2,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=5}, {type:SET_PROPERTY,data:_DstBlend=10}, {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:3,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=10}, {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=1}]},
            {value:4,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=1}, {type:SET_PROPERTY,data:_DstBlend=1},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:5,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:RenderType=Transparent},        {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=4}, {type:SET_PROPERTY,data:_DstBlend=1},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:6,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=2}, {type:SET_PROPERTY,data:_DstBlend=0},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]},
            {value:7,actions:[{type:SET_PROPERTY,data:render_queue=3000}, {type:SET_PROPERTY,data:render_type=Transparent},       {type:SET_PROPERTY,data:_BlendOp=0}, {type:SET_PROPERTY,data:_BlendOpAlpha=0}, {type:SET_PROPERTY,data:_Cutoff=0},  {type:SET_PROPERTY,data:_SrcBlend=2}, {type:SET_PROPERTY,data:_DstBlend=3},  {type:SET_PROPERTY,data:_AlphaToMask=0},  {type:SET_PROPERTY,data:_ZWrite=0}, {type:SET_PROPERTY,data:_ZTest=4},   {type:SET_PROPERTY,data:_AlphaPremultiply=0}]}
        }]}]}", Int) = 0
        

        _Cutoff ("Alpha Cuttoff--{condition_show:{type:PROPERTY_BOOL,data:_Mode==1}}", Range(0, 1.001)) = 0.5

        _MainTex ("Base Map --{reference_property:_Color,reference_properties:[_MainTexUV,_Saturation, _EnableVertexColor]}", 2D) = "white" {}
        [HideInInspector] _Color ("Color", Color) = (1,1,1,1)
        [HideInInspector] _Saturation ("Saturation", Range(-1,1)) = 0
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _MainTexUV ("UV", Int) = 0
        
        [HideInInspector] [ToggleUI] _EnableVertexColor ("Vertex Colors Mulitply", Float) = 0
               
                
        
        
        _Metallic ("Metallic", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Occlusion ("Occlusion", Range(0,1)) = 0

        
        [HideInInspector] [ToggleUI] _EnablePackedMap ("Enable Roughness Map ", Float) = 0
        [sRGBWarning] _MetallicGlossMap ("Mask Map--{tooltip:Metallic(R) Occlusion(G) Detail Mask(B) Smoothness(A),reference_properties:[_MetallicGlossMapUV],condition_show:{type:PROPERTY_BOOL,data:_EnablePackedMode==1},on_value_actions:[{value:0,actions:[{type:SET_PROPERTY,data:_EnablePackedMap=0}]},{value:1,actions:[{type:SET_PROPERTY,data:_EnablePackedMap=1}]}]} ", 2D) = "white" {}
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _MetallicGlossMapUV ("UV", Int) = 0

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

        

        
        [HideInInspector] m_Specular ("Reflections And Specular Highlights", Float) = 0
        [Toggle(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Specular Highlights", Float) = 1
        [Toggle(_GLOSSYREFLECTIONS_OFF)] _GlossyReflections("Reflections", Float) = 1
        _Reflectance ("Reflectance", Range(0,1)) = 0.5
        _AngularGlossiness ("Angular Glossiness", Range(0, 1)) = 0
        _ExposureOcclusion ("Exposure Occlusion Sensitivity", Range(0, 1)) = 0
        
        _MetallicFresnel ("Metallic Fresnel", Color) = (0,0,0,1)
        
        [HideInInspector] m_start_GSAA ("Geometric Specular Anti-Aliasing --{reference_property:_GSAA}", Float) = 0
        [HideInInspector] [Toggle(UNITY_UI_CLIP_RECT)] _GSAA("GSAA", Float) = 0
        [PowerSlider(3)] _specularAntiAliasingVariance ("Variance", Range(0.0, 1.0)) = 0.01
        [PowerSlider(3)] _specularAntiAliasingThreshold ("Threshold", Range(0.0, 1.0)) = 0.1
        [HideInInspector] m_end_GSAA ("", Float) = 0
        
        
        [HideInInspector] m_ShaderFeatures ("Shader Features", Float) = 0



        [HideInInspector] m_start_Emission ("Emission --{reference_property:_EnableEmission}", Float) = 0
        [HideInInspector] [ToggleUI] _EnableEmission ("Emission", Float) = 0
        _EmissionMap ("Emission Map--{reference_property:_EmissionColor,reference_properties:[_EmissionMapUV]}", 2D) = "white" {}
        [HideInInspector] [HDR] _EmissionColor ("Color", Color) = (0,0,0)
        [HideInInspector] [Enum(UV0, 0, UV1 (Lightmap), 1, UV2, 2)] _EmissionMapUV ("UV", Int) = 0
        [HideInInspector] m_end_Emission ("", Float) = 0




/*
        [HideInInspector] m_start_Iridescence ("Iridescence (Test) --{reference_property:_EnableIridescence}", Float) = 0
        [HideInInspector] [ToggleUI] _EnableIridescence ("Iridescence", Float) = 0
        _IridescenceIntensity ("Intensity", Range(0.0, 1.0)) = 0.5
        _IridescenceMap ("Emission Map", 2D) = "white" {}
        _NoiseMap ("Noise Map", 2D) = "white" {}
        [HideInInspector] m_end_Iridescence ("", Float) = 0
*/
        
        [HideInInspector] m_start_Lightmap ("Lightmap", Float) = 0
        [Toggle(_DETAIL_MULX2)] _BicubicLightmap ("Bicubic Lightmap Interpolation", Float) = 0
        _LightmapMultiplier ("Multiplier", Range(0, 2)) = 1
        _SpecularOcclusion ("Specular Occlusion", Range(0, 1)) = 0
        [HideInInspector] m_end_Lightmap ("", Float) = 0
        

        [HideInInspector] m_RenderingOptions ("Advanced Options", Float) = 0

    [HideInInspector] m_start_blending ("Blending", Float) = 0
        [Enum(Thry.BlendOp)]_BlendOp ("RGB Blend Op", Int) = 0
        [Enum(Thry.BlendOp)]_BlendOpAlpha ("Alpha Blend Op", Int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Blend", Int) = 0
        [HideInInspector] m_end_blending ("Blending", Float) = 0


        
        [Toggle(_SUNDISK_NONE)] _EnableSSDSAA ("Directional Shadows AA", Float) = 0
        [Toggle(UNITY_UI_ALPHACLIP)] _EnablePackedMode ("Packed Mode", Float) = 1
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
       // [Toggle(FXAA_LOW)] _PreviewQuest ("Preview Quest", Float) = 0
        
        
        

//        
        
        
        



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
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma fragmentoption ARB_precision_hint_fastest

            #pragma shader_feature UNITY_UI_CLIP_RECT // GSAA
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature UNITY_UI_ALPHACLIP
            #pragma shader_feature _DETAIL_MULX2
          //  #pragma shader_feature FXAA_LOW
            #pragma shader_feature _SUNDISK_NONE


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
            #pragma multi_compile_fwdadd_fullshadows
            #pragma shader_feature UNITY_UI_CLIP_RECT // GSAA
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature UNITY_UI_ALPHACLIP
        //    #pragma shader_feature FXAA_LOW

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
            #pragma multi_compile_shadowcaster
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
        //    #pragma shader_feature FXAA_LOW

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