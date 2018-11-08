// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/WaterSurf" {
	Properties{
		_Color("Color", Color) = (0,0,1,1)
		_SmoothNess("SmoothNess", Range(0.0,1.0)) = 0

		_NormalMap("Normalmap", 2D) = "white" {}
		_NormalMapMoveDir("Normalmap move dir", Vector) = (0,0,0,0)
		_NormalMapMoveSpeed("Normalmap move speed", Float) = 0
		
		[Header(Subsurface scattering)]
		_Power("Power", Float) = 0

		[Header(Wave crest foam)]
		_FoamTex("Foam texture", 2D) = "white" {}
		_FoamNormals("Foam normals", 2D) = "white" {}
		_FoamScale("Foam Scale", Float) = 1
		_FoamSharpness("Foam Sharpness", Float) = 1

		[Header(Base Wave)]
		_WaveLength1("Wavelength",  Float) = 0.1
		_Amplitude1("Amplitude", Float) = 0.001
		_Speed1("Speed", Float) = 1
		_DirectionX1("Direction X", Range(-1,1)) = 1
		_DirectionY1("Direction Y", Range(-1,1)) = 1
		_Steepness1("Steepness", Range(0,3)) = 0.1
		_FadeSpeed1("FadeSpeed", Float) = 1.0

		[Header(Additional Waves)]
		[Header(Wave 2)]
		[Toggle(WAVE2)] _Wave2Enabled("Enabled", Float) = 0
		_WaveLength2("Wavelength",  Float) = 0.1
		_Amplitude2("Amplitude", Float) = 0.001
		_Speed2("Speed", Float) = 1
		_DirectionX2("Direction X", Range(-1,1)) = 1
		_DirectionY2("Direction Y", Range(-1,1)) = 1
		_Steepness2("Steepness", Range(0,3)) = 0.1
		_FadeSpeed2("FadeSpeed", Float) = 1.0

		[Header(Wave 3)]
		[Toggle(WAVE3)] _Wave3Enabled("Enabled", Float) = 0
		_WaveLength3("Wavelength",  Float) = 0.1
		_Amplitude3("Amplitude", Float) = 0.001
		_Speed3("Speed", Float) = 1
		_DirectionX3("Direction X", Range(-1,1)) = 1
		_DirectionY3("Direction Y", Range(-1,1)) = 1
		_Steepness3("Steepness", Range(0,3)) = 0.1
		_FadeSpeed3("FadeSpeed", Float) = 1.0

		[Header(Wave 4)]
		[Toggle(WAVE4)] _Wave4Enabled("Enabled", Float) = 0
		_WaveLength4("Wavelength",  Float) = 0.1
		_Amplitude4("Amplitude", Float) = 0.001
		_Speed4("Speed", Float) = 1
		_DirectionX4("Direction X", Range(-1,1)) = 1
		_DirectionY4("Direction Y", Range(-1,1)) = 1
		_Steepness4("Steepness", Range(0,3)) = 0.1
		_FadeSpeed4("FadeSpeed", Float) = 1.0

		[Header(Wave 5)]
		[Toggle(WAVE5)] _Wave5Enabled("Enabled", Float) = 0
		_WaveLength5("Wavelength",  Float) = 0.1
		_Amplitude5("Amplitude", Float) = 0.001
		_Speed5("Speed", Float) = 1
		_DirectionX5("Direction X", Range(-1,1)) = 1
		_DirectionY5("Direction Y", Range(-1,1)) = 1
		_Steepness5("Steepness", Range(0,3)) = 0.1
		_FadeSpeed5("FadeSpeed", Float) = 1.0
	}
	SubShader{
		
		
		Tags{ "Lightmode" = "ForwardBase" "Queue" = "Transparent" "RenderType" = "Transparent" }
		ZWrite on
		Cull back
		Colormask 0
		Lighting Off
		// ------- PASS 1 ---------------
		CGPROGRAM

		#pragma surface surf Standard vertex:vert
		#include "UnityCG.cginc"
		#include "WaterIncludes.cginc"
		#pragma shader_feature WAVE2
		#pragma shader_feature WAVE3
		#pragma shader_feature WAVE4
		#pragma shader_feature WAVE5

		struct Input {
			float2 uv_MainTex;
		};
		
		void vert(inout appdata_full v) {
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex);

			float3 wavePointSum = worldPos + WavePointSum(worldPos).xyz;
			
			// Final vertex output
			v.vertex.xyz = mul(unity_WorldToObject, float4(wavePointSum, 1));
		}
		
		void surf(Input IN, inout SurfaceOutputStandard o) { }

		ENDCG

		// ------- PASS 2 ---------------
		ZWrite off
		Cull back
		Blend SrcAlpha OneMinusSrcAlpha
		Colormask RGBA

		CGPROGRAM

		#pragma surface surf StandardTranslucent vertex:vert alpha:fade
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "WaterIncludes.cginc"
		#pragma shader_feature WAVE2
		#pragma shader_feature WAVE3
		#pragma shader_feature WAVE4
		#pragma shader_feature WAVE5

		struct Input {
			float2 uv_NormalMap;
			float2 uv_FoamTex;
			float2 uv_FoamNormals;
			float crestFactor;
		};

		sampler2D _NormalMap;
		sampler2D _FoamTex;
		sampler2D _FoamNormals;
		half4 _NormalMapMoveDir;
		half _NormalMapMoveSpeed;
		float4 _Color;
		float4 _SSSColor;
		float _SmoothNess;

		float _Power;
		float _FoamSharpness;

		void vert(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex);

			float4 wavePointSum = WavePointSum(worldPos);
			float3 pos = worldPos + wavePointSum.xyz;

			// This is to avoid z fighting between the two passes. Can probably be done in a better way.
			pos.y += 0.0001;

			float3 waveNormalSum = WaveNormalSum(pos);

			o.crestFactor = wavePointSum.w;

			// Final vertex output
			v.vertex = mul(unity_WorldToObject, float4(pos,1));
			v.normal = normalize(waveNormalSum);
		}

		inline fixed4 LightingStandardTranslucent(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
		{
			// Original colour
			fixed4 pbr = LightingStandard(s, viewDir, gi);
			
			// Inverse Normal dot Light
			float NdotL = 1 - max(0, dot(gi.light.dir, s.Normal));

			// ViewDir dot Normal
			float VdotN = max(0, dot(viewDir, s.Normal));

			// ViewDir dot LightDir
			float VdotL = max(0, dot(normalize(-_WorldSpaceCameraPos.xyz), gi.light.dir));

			float SSS = NdotL * VdotN * VdotL * _Power;

			// Final add
			pbr.rgb = pbr.rgb + SSS * _Color;
			return pbr;
		}

		void LightingStandardTranslucent_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
			LightingStandard_GI(s, data, gi);
		}

		
		void surf(Input IN, inout SurfaceOutputStandard o) {
			float4 foamColor = tex2D(_FoamTex, IN.uv_FoamTex + _NormalMapMoveDir.xy * _NormalMapMoveSpeed * _Time.x);
			float foamFactor = pow(IN.crestFactor, _FoamSharpness);

			float3 waterNormal = normalize(o.Normal + UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap + _NormalMapMoveDir.xy * _NormalMapMoveSpeed * _Time.x)));
			float3 foamNormal = normalize(o.Normal + UnpackNormal(tex2D(_FoamNormals, IN.uv_FoamNormals + _NormalMapMoveDir.xy * _NormalMapMoveSpeed * _Time.x)));

			o.Albedo = lerp(_Color, foamColor, foamFactor);
			o.Smoothness = saturate(_SmoothNess - (foamFactor*2));
			o.Metallic = 0.0;
			o.Alpha = saturate(_Color.a + foamFactor);
			o.Normal = lerp(waterNormal, foamNormal, foamFactor);
		}

		ENDCG


	}
	Fallback "Diffuse"
}