// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Water"
{
	Properties
	{
		_Color("Color", Color) = (0,0,1,1)
		_Shininess ("Shininess", Range(0,10)) = 0

		_Normals("Bumpmap", 2D) = "black" {}

		[Header(Wave 1)]
		_WaveLength("Wavelength",  Float) = 0.1
		_Amplitude("Amplitude", Float) = 0.001
		_Speed("Speed", Float) = 1
		_DirectionX("Direction X", Range(-1,1)) = 1
		_DirectionY("Direction Y", Range(-1,1)) = 1
		_Steepness("Steepness", Range(0,1)) = 0.1
		_FadeSpeed("FadeSpeed", Float) = 1.0
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
			float _FadeSpeed;

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

				float sinCurve = sin(_Time.x * _FadeSpeed) * 0.5 + 0.5;
				float amp1 = clamp(_Amplitude * sinCurve, 0, 1);

				// Wave points, needed for Z-writing
				float3 wavePoint1 = WavePoint(worldPos.xz, _Amplitude* 1.2, _WaveLength, _Speed, direction1, Q);
				float3 wavePoint2 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction2, Q);
				float3 wavePoint3 = WavePoint(worldPos.xz, amp1, _WaveLength, _Speed, direction3, Q);

				float3 totalWave = worldPos + wavePoint1 + wavePoint2 + wavePoint3;

				// Final vertex output
				o.vertex = mul(UNITY_MATRIX_VP, float4(totalWave, 1.));
				o.normal = v.normal; //normalize(totalNormal);

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
				float2 uv_NormalMap : TEXCOORD0;
			};

			float4 _Color;
			sampler2D _Normals;
			float4 _Normals_ST;
			float _WaveLength;
			float _Amplitude;
			float _Speed;
			float _DirectionX;
			float _DirectionY;
			float _Steepness;
			float _Shininess;
			float _FadeSpeed;

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

				float sinCurve = sin(_Time.x * _FadeSpeed) * 0.5 + 0.5;
				float amp1 = clamp(_Amplitude * sinCurve, 0, 1);

				// Wave points
				float3 wavePoint1 = WavePoint(worldPos.xz, _Amplitude * 1.2, _WaveLength, _Speed, direction1, Q);
				float3 wavePoint2 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction2, Q);
				float3 wavePoint3 = WavePoint(worldPos.xz, amp1, _WaveLength, _Speed, direction3, Q);

				float3 totalWave = worldPos + wavePoint1 +wavePoint2 + wavePoint3;

				// Wave normals
				float3 waveNormal1 = WaveNormal(totalWave, _Amplitude* 1.2, _WaveLength, _Speed, direction1, Q);
				float3 waveNormal2 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction2, Q);
				float3 waveNormal3 = WaveNormal(totalWave, amp1, _WaveLength, _Speed, direction3, Q);

				float3 totalNormal = waveNormal1 + waveNormal2 + waveNormal3;
				
				totalNormal.x = -totalNormal.x;
				totalNormal.y = 1-totalNormal.y;
				totalNormal.z = -totalNormal.z;
				
				// Final vertex output
				o.worldPos = mul(UNITY_MATRIX_VP,  float4(totalWave, 1.));
				o.worldNormal = normalize(mul(totalNormal, (float3x3)unity_WorldToObject));
				o.uv_NormalMap = TRANSFORM_TEX(v.texcoord, _Normals);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				
				fixed4 col = _Color;
				
				float3 addedNormal = tex2D(_Normals, i.uv_NormalMap.yx);
				i.worldNormal *= addedNormal;

				// Light direction
				float3 lightDir = _WorldSpaceLightPos0.xyz;

				// Camera direction
				float3 viewDir = normalize(i.worldPos.xyz - _WorldSpaceCameraPos.xyz);

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
				half specPow = pow(RdotV, _Shininess);

				// Sample the ramp texture for a smooth falloff.
				half3 specRamp = lerp(float3(0,0,0), float3(1,1,1), specPow);
				specRamp *= _LightColor0;

				float3 light = diffuse;// +specRamp;

				col.rgb *= light;
				col.rgb += specRamp;

				col.a = _Color.a;
				return col;
				
			}

			ENDCG
		}
	}
}
