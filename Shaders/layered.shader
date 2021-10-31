Shader "z3y/other/layered lit"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0.5
		_Occlusion("Occlusion", Range(0, 1)) = 0
		_BumpScale("Bump Scale", Range(0, 10)) = 1
		_MainTex_ST ("Tile Offset", Vector) = (1,1,0,0)
		[SingleLineTexture] _HeightMap ("Height RGB", 2D) = "white" {}

		[Header(Mask Map  Metallic R  Occlusion G  Smoothness A)]

		[Header(Layer Black)] [Space]
		[SingleLineTexture] _MainTex0 ("Base Map", 2D) = "white" {}
		[SingleLineTexture] _MaskMap0 ("Mask Map", 2D) = "white" {}
		[SingleLineTexture] [Normal] _BumpMap0 ("Normal Map", 2D) = "bump" {}

		[Header(Layer Red)] [Space]
		[SingleLineTexture] _MainTex1 ("Base Map", 2D) = "white" {}
		[SingleLineTexture] _MaskMap1 ("Mask Map", 2D) = "white" {}
		[SingleLineTexture] [Normal] _BumpMap1 ("Normal Map", 2D) = "bump" {}


		[Header(Layer Green)] [Space]
        [Toggle(LAYER3)] _EnableLayer3 ("Enable Layer", Int) = 0
		[SingleLineTexture] _MainTex2 ("Base Map", 2D) = "white" {}
		[SingleLineTexture] _MaskMap2 ("Mask Map", 2D) = "white" {}
		[SingleLineTexture] [Normal] _BumpMap2 ("Normal Map", 2D) = "bump" {}

		[Header(Layer Blue)] [Space]
        [Toggle(LAYER4)] _EnableLayer4 ("Enable Layer", Int) = 0
		[SingleLineTexture] _MainTex3 ("Base Map", 2D) = "white" {}
		[SingleLineTexture] _MaskMap3 ("Mask Map", 2D) = "white" {}
		[SingleLineTexture] [Normal] _BumpMap3 ("Normal Map", 2D) = "bump" {}

		[Space]
        [Toggle(SPLATMAP)] _UseSplat ("Use Splat Map", Int) = 0
		[SingleLineTexture] _SplatMap ("Splat Map", 2D) = "black" {}

	}
	SubShader
	{
		Tags
		{
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}

		Cull Back

		CGINCLUDE
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityPBSLighting.cginc"
			#pragma target 5.0
            #pragma multi_compile_instancing
			#pragma shader_feature_local LAYER3
			#pragma shader_feature_local LAYER4
			#pragma shader_feature_local SPLATMAP

			uniform float4 _Color;
			uniform float _Metallic;
			uniform float _Smoothness;
			uniform float _Occlusion;
			uniform float _BumpScale;
			uniform Texture2D _SplatMap;

			uniform Texture2D _MainTex0;
			uniform Texture2D _MainTex1;
			uniform Texture2D _MainTex2;
			uniform Texture2D _MainTex3;

			uniform Texture2D _MaskMap0;
			uniform Texture2D _MaskMap1;
			uniform Texture2D _MaskMap2;
			uniform Texture2D _MaskMap3;

			uniform Texture2D _BumpMap0;
			uniform Texture2D _BumpMap1;
			uniform Texture2D _BumpMap2;
			uniform Texture2D _BumpMap3;

			uniform Texture2D _HeightMap;
			uniform SamplerState sampler_MainTex0;
			uniform SamplerState sampler_BumpMap0;
			uniform float4 _MainTex_ST;

			
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float3 uv0 : TEXCOORD0;
				#ifndef UNITY_PASS_SHADOWCASTER
				float2 uv1 : TEXCOORD1;

				float4 tangent : TANGENT;
				float4 color : COLOR;
				#endif

				uint vertexId : SV_VertexID;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				#ifndef UNITY_PASS_SHADOWCASTER
				float4 pos : SV_POSITION;
				float3 normal : NORMAL;
				float3 wPos : TEXCOORD0;
				float4 color : TEXCOORD3;

				float3 tangent : TEXCOORD4;
				float3 bitangent : TEXCOORD5;

				SHADOW_COORDS(6)
				#else
				V2F_SHADOW_CASTER;
				#endif
				float4 uv : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				#ifdef UNITY_PASS_SHADOWCASTER
				TRANSFER_SHADOW_CASTER_NOPOS(o, o.pos);
				#else
				o.wPos = mul(unity_ObjectToWorld, v.vertex);
				o.pos = UnityWorldToClipPos(o.wPos);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
        		o.bitangent = cross(o.tangent, o.normal) * v.tangent.w;
				o.color = v.color;
				o.uv.zw = v.uv1;

				TRANSFER_SHADOW(o);
				#endif
				o.uv.xy = v.uv0;
				

				
				return o;
			}

			float4 BlendedTexture(Texture2D tex0, Texture2D tex1, Texture2D tex2, Texture2D tex3, SamplerState s, float2 uv, float4 blendWeight)
			{
				float4 w = blendWeight;
				float4 t[4];

				t[0] = tex0.Sample(s, uv);
				t[1] = tex1.Sample(s, uv);
				#ifdef LAYER3
				t[2] = tex2.Sample(s, uv);
				#else
				t[2] = 0;
				#endif
				#ifdef LAYER4
				t[3] = tex3.Sample(s, uv);
				#else
				t[3] = 0;
				#endif

				float4 bt = lerp(t[0], t[1], w.r);
				#ifdef LAYER3
				bt = lerp(bt, t[2], w.g);
				#endif
				#ifdef LAYER4
				bt = lerp(bt, t[3], w.b);
				#endif

				return saturate(bt);
			}

			float computeSpecularAO(float NoV, float ao, float roughness) {
				return clamp(pow(NoV + ao, exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
			}

			#ifndef UNITY_PASS_SHADOWCASTER
			float4 frag(v2f i) : SV_TARGET
			{
				float3 normal = i.normal;
				float3 tangent = i.tangent;
				float3 bitangent = i.bitangent;

				float2 mainUV = TRANSFORM_TEX(i.uv.xy, _MainTex);

				#ifdef SPLATMAP
					float4 blendWeight = _SplatMap.Sample(sampler_MainTex0, i.uv.xy);
				#else
					float4 blendWeight = i.color;
				#endif

				blendWeight /= _HeightMap.Sample(sampler_MainTex0, mainUV);
				blendWeight = saturate(blendWeight);

				float4 texCol = BlendedTexture(_MainTex0, _MainTex1, _MainTex2, _MainTex3, sampler_MainTex0, mainUV, blendWeight);
				float4 packedMap = BlendedTexture(_MaskMap0, _MaskMap1, _MaskMap2, _MaskMap3, sampler_MainTex0, mainUV, blendWeight);
				float4 normalMap = BlendedTexture(_BumpMap0, _BumpMap1, _BumpMap2, _BumpMap3, sampler_BumpMap0, mainUV, blendWeight);
				// float4 normalMap = float4(0.5,0.5,1,1);

				texCol *= _Color;

				float2 uv = i.uv;

				

				UNITY_LIGHT_ATTENUATION(attenuation, i, i.wPos.xyz);

				float3 specularTint;
				float oneMinusReflectivity;
				float smoothness = _Smoothness * packedMap.a;
				float metallic = _Metallic * packedMap.r;
				float occlusion = lerp(1, packedMap.g, _Occlusion);

				#define NORMALMAP
				#ifdef NORMALMAP
					float3 tangentNormal = UnpackScaleNormal(normalMap, _BumpScale);
					tangentNormal.g *=  -1;

					float3 calcedNormal = normalize
					(
						tangentNormal.x * tangent +
						tangentNormal.y * bitangent +
						tangentNormal.z * normal
					);

					normal = calcedNormal;
					tangent = normalize(cross(normal, bitangent));
					bitangent = normalize(cross(normal, tangent));
				#endif


				float3 albedo = DiffuseAndSpecularFromMetallic(
					texCol, metallic, specularTint, oneMinusReflectivity
				);
				
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.wPos);
				UnityLight light;
				light.color = attenuation * _LightColor0.rgb;
				light.dir = normalize(UnityWorldSpaceLightDir(i.wPos));
				UnityIndirect indirectLight;
				#ifdef UNITY_PASS_FORWARDADD
				indirectLight.diffuse = indirectLight.specular = 0;
				#else
				#ifndef LIGHTMAP_ON
				indirectLight.diffuse = max(0, ShadeSH9(float4(normal, 1)));
				#else
				float2 lightmapUV = i.uv.zw * unity_LightmapST.xy + unity_LightmapST.zw;
				float3 lightMap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, lightmapUV));
				#if defined(DIRLIGHTMAP_COMBINED)
					float4 lightMapDirection = UNITY_SAMPLE_TEX2D_SAMPLER (unity_LightmapInd, unity_Lightmap, lightmapUV);
					lightMap = DecodeDirectionalLightmap(lightMap, lightMapDirection, normal);
				#endif
				indirectLight.diffuse = lightMap;
				#endif
				float3 reflectionDir = reflect(-viewDir, normal);
				Unity_GlossyEnvironmentData envData;
				envData.roughness = 1 - smoothness;
				envData.reflUVW = reflectionDir;
				indirectLight.specular = Unity_GlossyEnvironment(
					UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
				);
				float NoV = abs(dot(normal, viewDir)) + 1e-5;
				indirectLight.specular *= computeSpecularAO(NoV, occlusion, smoothness);
				#endif

				float3 col = UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, smoothness,
					normal, viewDir,
					light, indirectLight
				);

				#ifdef UNITY_PASS_FORWARDADD
				return float4(col, 0);
				#else
				return float4(col, 1);
				#endif
			}
			#else
			float4 frag(v2f i) : SV_Target
			{
				float alpha = 1;
				SHADOW_CASTER_FRAGMENT(i)
			}
			#endif
		ENDCG

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase_fullshadows
			ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd_fullshadows
			ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ShadowCaster" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			ENDCG
		}
	}
}
