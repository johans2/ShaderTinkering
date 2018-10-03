Shader "Custom/WaterSurf" {
	Properties{
		_WaveLength("Wavelength",  Float) = 0.1
		_Amplitude("Amplitude", Float) = 0.001
		_Speed("Speed", Float) = 1
		_Color("Color", Color) = (0,0,1,1)
	}
	SubShader{
		
		
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		ZWrite on
		Cull back
		Colormask 0
		Lighting Off
		// ------- PASS 1 ---------------
		CGPROGRAM

		#pragma surface surf StandardSpecular vertex:vert
		#include "UnityCG.cginc"
		#include "WaterIncludes.cginc"
		

		struct Input {
			float2 uv_MainTex;
		};
		
		sampler2D _MainTex;
		float4 _Color;
		float _WaveLength;
		float _Amplitude;
		float _Speed;

		void vert(inout appdata_full v) {

			// Wave directions
			float2 direction1 = normalize(float2(1, 0));
			float2 direction2 = normalize(float2(0, 1));
			float2 direction3 = normalize(float2(0.3, 0.4));

			float3 worldPos = v.vertex.xyz; //mul(unity_ObjectToWorld, v.vertex).xyz;

			float Q = 0.1;

			// Wave points
			float3 wavePoint1 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction1, Q);
			float3 wavePoint2 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction2, Q);
			float3 wavePoint3 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction3, Q);

			float3 totalWave = worldPos + wavePoint1 + wavePoint2 + wavePoint3;

			// Wave normals
			float3 waveNormal1 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction1, Q);
			float3 waveNormal2 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction2, Q);
			float3 waveNormal3 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction3, Q);

			float3 totalNormal = waveNormal1 + waveNormal2 + waveNormal3;

			totalNormal.x = -totalNormal.x;
			totalNormal.y = 1 - totalNormal.y;
			totalNormal.z = -totalNormal.z;

			// Final vertex output
			v.vertex.xyz += totalWave;
			v.normal = normalize(totalNormal);
		}
		
		void surf(Input IN, inout SurfaceOutputStandardSpecular o) {
			/*
			o.Albedo = _Color.rgb;
			o.Smoothness = .5;
			o.Alpha = 0.5f;
			*/
		}

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

		struct Input {
			float2 uv_MainTex;
		};

		sampler2D _MainTex;
		float4 _Color;
		float _WaveLength;
		float _Amplitude;
		float _Speed;

		void vert(inout appdata_full v) {

			// Wave directions
			float2 direction1 = normalize(float2(1, 0));
			float2 direction2 = normalize(float2(0, 1));
			float2 direction3 = normalize(float2(0.3, 0.4));

			float3 worldPos = v.vertex.xyz; //mul(unity_ObjectToWorld, v.vertex).xyz;

			float Q = 0.1;

			// Wave points
			float3 wavePoint1 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction1, Q);
			float3 wavePoint2 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction2, Q);
			float3 wavePoint3 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction3, Q);

			float3 totalWave = worldPos + wavePoint1 + wavePoint2 + wavePoint3;

			// Wave normals
			float3 waveNormal1 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction1, Q);
			float3 waveNormal2 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction2, Q);
			float3 waveNormal3 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction3, Q);

			float3 totalNormal = waveNormal1 + waveNormal2 + waveNormal3;

			totalNormal.x = -totalNormal.x;
			totalNormal.y = 1 - totalNormal.y;
			totalNormal.z = -totalNormal.z;

			// Final vertex output
			v.vertex.xyz += totalWave;
			v.normal = normalize(totalNormal);
		}

		void surf(Input IN, inout SurfaceOutputStandardSpecular o) {
			o.Albedo = _Color.rgb;
			o.Smoothness = .5;
			o.Alpha = _Color.a;
		}

		ENDCG


	}
	Fallback "Diffuse"
}