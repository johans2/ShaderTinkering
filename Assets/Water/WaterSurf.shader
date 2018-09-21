Shader "Custom/WaterSurf" {
	Properties{
		_WaveLength("Wavelength",  Float) = 0.1
		_Amplitude("Amplitude", Float) = 0.001
		_Speed("Speed", Float) = 1
		_Color("Color", Color) = (0,0,1,1)
	}
	SubShader{
		
		
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		ZWrite off

		CGPROGRAM

		#pragma surface surf Lambert vertex:vert
		#include "UnityCG.cginc"
		#include "WaterIncludes.cginc"
		#include "UnityLightingCommon.cginc"
		

		struct Input {
			float2 uv_MainTex;
		};
		
		sampler2D _MainTex;
		float4 _Color;
		float _WaveLength;
		float _Amplitude;
		float _Speed;

		float _Amount;
	
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

			half nl = max(0, dot(totalNormal, _WorldSpaceLightPos0.xyz));


			// Final vertex output
			v.vertex.xyz += totalWave;
			v.normal = normalize(totalNormal);
			//v.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			//v.diffLight = nl * _LightColor0;


			//v.vertex.xyz += v.normal * _Amount;
		}
		
		void surf(Input IN, inout SurfaceOutput o) {
			o.Albedo = _Color.rgb;
			o.Alpha = 0.5f;
		}

		ENDCG
	}
	Fallback "Diffuse"
}