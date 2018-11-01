// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Water"
{
	Properties
	{
		_Color("Color", Color) = (0,0,1,1)
		_Shininess ("Shininess", Range(0.2,10)) = 0

		_Normals("Bumpmap", 2D) = "white" {}

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
		[Toggle(WAVE2)] _Wave2Enabled ("Enabled", Float) = 0
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
			#pragma shader_feature WAVE2
			#pragma shader_feature WAVE3
			#pragma shader_feature WAVE4
			#pragma shader_feature WAVE5

			struct v2f
			{
				float4 worldPos : SV_POSITION;
				float3 normal : NORMAL;
			};

			float4 _Color;

			// https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
			v2f vert(appdata_full v)
			{
				v2f o;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				float3 wavePointSum = worldPos + WavePointSum(worldPos);

				// Final vertex output
				o.worldPos = mul(UNITY_MATRIX_VP, float4(wavePointSum, 1.));
				o.normal = v.normal;

				return o;
			}

			fixed4 frag(v2f i) : COLOR
			{
				return fixed4(0,0,0,0);
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
			#pragma shader_feature WAVE2
			#pragma shader_feature WAVE3
			#pragma shader_feature WAVE4
			#pragma shader_feature WAVE5

			struct v2f
			{
				float4 worldPos : SV_POSITION;
				float3 worldNormal : NORMAL;
				float2 uv_NormalMap : TEXCOORD0;
			};

			float4 _Color;
			sampler2D _Normals;

			float4 _Normals_ST;
			float _Shininess;


			// https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
			v2f vert (appdata_full v)
			{
				v2f o;
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				float3 wavePointSum = worldPos + WavePointSum(worldPos);

				float3 waveNormalSum = WaveNormalSum(wavePointSum); //waveNormal1 + waveNormal2 + waveNormal3;
				
				// Final vertex output
				o.worldPos = mul(UNITY_MATRIX_VP,  float4(wavePointSum + float3(0,0.0001,0), 1.));
				o.worldNormal = normalize(mul(waveNormalSum, (float3x3)unity_WorldToObject));
				o.uv_NormalMap = TRANSFORM_TEX(v.texcoord, _Normals);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				
				fixed4 col = _Color;

				float nDotUp = clamp(dot(float3(0, 1, 0), i.worldNormal) , 0, 1);
				
				float3 addedNormal = tex2D(_Normals, i.uv_NormalMap.yx);
				i.worldNormal *= (addedNormal * 1.2);

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
				half specular = pow(RdotV, _Shininess) * _LightColor0;

				float3 light = diffuse + specular;

				col.rgb *= light;
				
				col.a = _Color.a + specular;
				
				fixed4 red = fixed4(1, 0, 0, 1);
				fixed4 trans = fixed4(0, 0, 0, 0);

				return col;
			}

			ENDCG
		}
	}
}
