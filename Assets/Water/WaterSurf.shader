﻿Shader "Custom/WaterSurf" {
	Properties{
		_Color("Color", Color) = (0,0,1,1)
		_SmoothNess("SmoothNess", Range(0.0,1.0)) = 0

		_BumpMap("Bumpmap", 2D) = "white" {}
		_BumpMapMoveDir("Bumpmap move dir", Vector) = (0,0,0,0)
		_BumpMapMoveSpeed("Bumpmap move speed", Float) = 0
		
		[Header(Subsurface scattering)]
		_Distortion("Distortion", Float) = 0
		_Power("Power", Float) = 0
		_Scale("Scale", Float) = 0
		_SSSColor("Color", Color) = (1,1,1,1)

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

		#pragma surface surf StandardSpecular fullforwardshadows vertex:vert
		#include "UnityCG.cginc"
		#include "WaterIncludes.cginc"
		#pragma shader_feature WAVE2
		#pragma shader_feature WAVE3
		#pragma shader_feature WAVE4
		#pragma shader_feature WAVE5

		struct Input {
			float2 uv_MainTex;
		};
		
		sampler2D _MainTex;
		float4 _Color;
		float _WaveLength;
		float _Amplitude;
		float _Speed;

		void vert(inout appdata_full v) {
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex);

			float3 wavePointSum = worldPos + WavePointSum(worldPos.xyz);
			
			// Final vertex output
			v.vertex.xyz = mul(unity_WorldToObject, float4(wavePointSum, 1));
		}
		
		void surf(Input IN, inout SurfaceOutputStandardSpecular o) { }

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
			float2 uv_MainTex;
			float2 uv_BumpMap;
		};

		sampler2D _MainTex;
		sampler2D _BumpMap;
		half4 _BumpMapMoveDir;
		half _BumpMapMoveSpeed;
		float4 _Color;
		float4 _SSSColor;
		float _SmoothNess;

		float _Distortion;
		float _Power;
		float _Scale;

		float3 unmodifiedNormal;

		void vert(inout appdata_full v) {
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex);

			float3 wavePointSum = worldPos + WavePointSum(worldPos);

			// This is to avoid z fighting between the two passes. Can probably be done in a better way.
			wavePointSum.y += 0.0001;

			float3 waveNormalSum = WaveNormalSum(wavePointSum);
			// Final vertex output
			v.vertex = mul(unity_WorldToObject, float4(wavePointSum,1));
			v.normal = normalize(waveNormalSum);
		}

		inline fixed4 LightingStandardTranslucent(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
		{
			// Original colour
			fixed4 pbr = LightingStandard(s, viewDir, gi);
			
			// Inverse Normal dot Light
			float NdotL = 1 - max(0, dot(gi.light.dir, s.Normal));

			// ViewDir dot Normal
			float VdotN = pow( max(0, dot(viewDir, s.Normal)), _Power);

			// ViewDir dot LightDir
			float VdotL = max(0, dot(normalize(-_WorldSpaceCameraPos.xyz), gi.light.dir));

			// --- Translucency ---
			float3 L = gi.light.dir;
			float3 V = viewDir;
			float3 N = unmodifiedNormal;// s.Normal;

			float3 H = normalize(L + N * _Distortion);
			float I = pow(saturate(dot(V, -H)), _Power) * _Scale;

			float SSS = NdotL * VdotN * VdotL *2;

			// Final add
			pbr.rgb = pbr.rgb + SSS * _Color;
			return pbr;
		}

		void LightingStandardTranslucent_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
			LightingStandard_GI(s, data, gi);
		}

		
		void surf(Input IN, inout SurfaceOutputStandard o) {
			o.Albedo = _Color.rgb;
			o.Smoothness = _SmoothNess;
			o.Metallic = 0.0;
			o.Alpha = _Color.a;
			unmodifiedNormal = o.Normal;
			o.Normal += UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap + _BumpMapMoveDir.xy * _BumpMapMoveSpeed * _Time.x));
		}

		ENDCG


	}
	Fallback "Diffuse"
}