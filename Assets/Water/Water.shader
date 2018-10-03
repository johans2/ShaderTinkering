﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Water"
{
	Properties
	{
		_Color("Color", Color) = (0,0,1,1)
		_Shininess ("Shininess", Range(0,10)) = 0

		[Header(Wave 1)]
		_WaveLength("Wavelength",  Float) = 0.1
		_Amplitude("Amplitude", Float) = 0.001
		_Speed("Speed", Float) = 1
		_DirectionX("Direction X", Range(-1,1)) = 1
		_DirectionY("Direction Y", Range(-1,1)) = 1
		_Steepness("Steepness", Range(0,1)) = 0.1
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "LightMode" = "ForwardBase" "RenderType" = "Transparent" }
		
		// -------------- Z WRITE AND VERTEX ANIMATION --------------
		Pass { 
			ZWrite on
			Colormask 0

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "WaterIncludes.cginc"
			#include "UnityLightingCommon.cginc"

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
			};

			float4 _Color;
			float _WaveLength;
			float _Amplitude;
			float _Speed;
			float _DirectionX;
			float _DirectionY;
			float _Steepness;

			// https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
			v2f vert(appdata_full v)
			{
				v2f o;
				// Wave directions
				float2 direction1 = normalize(float2(_DirectionX, _DirectionY));
				float2 direction2 = normalize(float2(0,1));
				float2 direction3 = normalize(float2(0.3, 0.4));

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				float Q = _Steepness;

				// Wave points
				float3 wavePoint1 = WavePoint(worldPos.xz, _Amplitude* 1.2, _WaveLength, _Speed, direction1, Q);
				float3 wavePoint2 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction2, Q);
				float3 wavePoint3 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction3, Q);

				float3 totalWave = worldPos + wavePoint1 + wavePoint2 + wavePoint3;

				// Wave normals
				float3 waveNormal1 = WaveNormal(totalWave, _Amplitude* 1.2, _WaveLength, _Speed, direction1, Q);
				float3 waveNormal2 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction2, Q);
				float3 waveNormal3 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction3, Q);

				float3 totalNormal = waveNormal1 + waveNormal2 + waveNormal3;

				totalNormal.x = -totalNormal.x;
				totalNormal.y = 1 - totalNormal.y;
				totalNormal.z = -totalNormal.z;

				// Final vertex output
				o.vertex = mul(UNITY_MATRIX_VP, float4(totalWave, 1.));
				o.normal = normalize(totalNormal);

				return o;
			}

			fixed4 frag(v2f i) : COLOR
			{
				return fixed4(0,0,0,1);
			}

			ENDCG
		}

		// -------------- COLOR, LIGHT AND BLENDING --------------
		Pass
		{
			ZWrite off
			Blend SrcAlpha OneMinusSrcAlpha
			
			Cull back
			LOD 200

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "WaterIncludes.cginc"
			#include "UnityLightingCommon.cginc"

			struct v2f
			{
				float4 worldPos : SV_POSITION;
				float3 worldNormal : NORMAL;
			};

			float4 _Color;
			float _WaveLength;
			float _Amplitude;
			float _Speed;
			float _DirectionX;
			float _DirectionY;
			float _Steepness;
			float _Shininess;

			// https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
			v2f vert (appdata_full v)
			{
				v2f o;
				
				// Wave directions
				float2 direction1 = normalize(float2(_DirectionX, _DirectionY));
				float2 direction2 = normalize(float2(0,1));
				float2 direction3 = normalize(float2(0.3, 0.4));

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				float Q = _Steepness;

				// Wave points
				float3 wavePoint1 = WavePoint(worldPos.xz, _Amplitude * 1.2, _WaveLength, _Speed, direction1, Q);
				float3 wavePoint2 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction2, Q);
				float3 wavePoint3 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction3, Q);

				float3 totalWave = worldPos + wavePoint1 +wavePoint2 + wavePoint3;

				// Wave normals
				float3 waveNormal1 = WaveNormal(totalWave, _Amplitude* 1.2, _WaveLength, _Speed, direction1, Q);
				float3 waveNormal2 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction2, Q);
				float3 waveNormal3 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction3, Q);

				float3 totalNormal = waveNormal1 + waveNormal2 + waveNormal3;
				
				totalNormal.x = -totalNormal.x;
				totalNormal.y = 1-totalNormal.y;
				totalNormal.z = -totalNormal.z;
				
				// Final vertex output
				o.worldPos = mul(UNITY_MATRIX_VP,  float4(totalWave, 1.));
				o.worldNormal = normalize(mul(totalNormal, (float3x3)unity_WorldToObject)); //normalize(totalNormal);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				
				fixed4 col = _Color;
				
				// Light direction
				float3 lightDir = _WorldSpaceLightPos0.xyz;

				// Camera direction
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

				// -------------------- DIFFUSE LIGHT ----------------------

				// This will be light added to all parts of the obejct, including dark ones.
				float3 indirectDiffuse = unity_AmbientSky;

				// Compute the diffuse lighting
				float NdotL = max(0., dot(i.worldNormal, lightDir));

				// Diffuse based on light source
				float3 directDiffuse = _LightColor0;

				// Light = direct + indirect;
				float3 diffuse = lerp(indirectDiffuse, directDiffuse, NdotL);

				// -------------------- SPECULAR LIGHT ----------------------
				
				// Get the light reflection across the normal.
				half3 refl = normalize(reflect(-lightDir, i.worldNormal));

				// Calculate dot product between the reflection diretion and the view direction [0...1]
				half RdotV = max(0., dot(refl, viewDir));

				// Make large values really large and small values really small.
				half specPow = clamp(0,1, pow(RdotV, _Shininess));

				// Sample the ramp texture for a smooth falloff.
				half3 specRamp = lerp(float3(0,0,0), float3(1,1,1), specPow);
				specRamp *= _LightColor0;

				// Multiply by NdotL to make non lit areas not  get spec (kinda works).
				//half3 spec = specRamp * _LightColor0 * _SpecColor * pow(_SpecIntensity, 2);

				// Multiply by NdotL to make non lit areas not  get spec (kinda works).
				//half3 spec = specPow * _LightColor0 * float3(1,,1);
				
				float3 light = diffuse + specRamp;

				col.rgb *= light;
				col.a = _Color.a;
				/*
				fixed4 colN = fixed4(1, 1, 1, 1);
				colN.r *= i.normal.x * 0.5 + 0.5;
				colN.g *= i.normal.y * 0.5 + 0.5;
				colN.b *= i.normal.z * 0.5 + 0.5;
				return colN;
				*/

				//return float4(1, 0, 0, 1);

				return col;
				
			}

			ENDCG
		}
	}
}
