// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Water"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_WaveLength("Wavelength",  Float) = 0.1
		_Amplitude("Amplitude", Float) = 0.001
		_Speed("Speed", Float) = 1
		_Color("Color", Color) = (0,0,1,1)
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		LOD 200
		Cull back
		ZWrite off
		Blend One One
		BlendOp Add

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "WaterIncludes.cginc"
			#include "UnityLightingCommon.cginc"

			struct vertData {
				float3 position : POSITION;
				float2 uv : TEXCOORD0;

			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD1;
				float3 diffLight : TEXCOORD2;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _WaveLength;
			float _Amplitude;
			float _Speed;

			// https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
			v2f vert (appdata_full v)
			{
				v2f o;
				// Wave directions
				float2 direction1 = normalize(float2(1,0));
				float2 direction2 = normalize(float2(0,1));
				float2 direction3 = normalize(float2(0.3, 0.4));

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				float Q = 0.1;

				// Wave points
				float3 wavePoint1 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction1, Q);
				float3 wavePoint2 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction2, Q);
				float3 wavePoint3 = WavePoint(worldPos.xz, _Amplitude, _WaveLength, _Speed, direction3, Q);

				float3 totalWave = worldPos + wavePoint1 +wavePoint2 + wavePoint3;

				// Wave normals
				float3 waveNormal1 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction1, Q);
				float3 waveNormal2 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction2, Q);
				float3 waveNormal3 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction3, Q);

				float3 totalNormal = waveNormal1 + waveNormal2 + waveNormal3;
				
				totalNormal.x = -totalNormal.x;
				totalNormal.y = 1-totalNormal.y;
				totalNormal.z = -totalNormal.z;

				half nl = max(0, dot(totalNormal, _WorldSpaceLightPos0.xyz));


				// Final vertex output
				o.vertex = mul(UNITY_MATRIX_VP, float4(totalWave, 1.));
				o.normal = normalize(totalNormal);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.diffLight = nl * _LightColor0;


				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				
				fixed4 col = _Color;
				
				// Light direction
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				// Camera direction
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.vertex.xyz);

				// -------------------- DIFFUSE LIGHT ----------------------

				// This will be light added to all parts of the obejct, including dark ones.
				float3 indirectDiffuse = unity_AmbientSky;

				// Compute the diffuse lighting
				float NdotL = max(0., dot(i.normal, lightDir));

				// Diffuse based on light source
				float3 directDiffuse = _LightColor0;

				// Light = direct + indirect;
				float3 diffuse = lerp(indirectDiffuse, directDiffuse, NdotL);

				col.a = 0.5;
				col.rgb *= diffuse;
				/*
				fixed4 col = fixed4(1, 1, 1, 1);
				col.r *= i.normal.x * 0.5 + 0.5;
				col.g *= i.normal.y * 0.5 + 0.5;
				col.b *= i.normal.z * 0.5 + 0.5;
				*/
				
				return col;
			}

			ENDCG
		}
	}
}
