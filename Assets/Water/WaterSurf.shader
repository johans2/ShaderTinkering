Shader "Custom/WaterSurf" {
	Properties{
		_Color("Color", Color) = (0,0,1,1)
		_SmoothNess("SmoothNess", Range(0.0,1.0)) = 0

		_BumpMap("Bumpmap", 2D) = "white" {}

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

		#pragma surface surf StandardSpecular vertex:vert
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

		#pragma surface surf StandardSpecular vertex:vert alpha:fade
		#include "UnityCG.cginc"
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
		float4 _Color;
		float _SmoothNess;

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

		void surf(Input IN, inout SurfaceOutputStandardSpecular o) {
			o.Albedo = _Color.rgb;
			o.Smoothness = _SmoothNess;
			o.Alpha = _Color.a;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
		}

		ENDCG


	}
	Fallback "Diffuse"
}