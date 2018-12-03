// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/WaterSurf" {
	Properties{
		// Color
		_Color("Color", Color) = (0,0,1,1)
		_SmoothNess("SmoothNess", Range(0.0,1.0)) = 0
        _WaveFoamDir("Wave foam direction", Vector) = (0,0,0,0)

		// Normals
		[Header(Distortions 1)]
		_NormalMap1("Normalmap 1", 2D) = "white" {}
		_NormalMapMoveDir1("Normalmap 1 move dir", Vector) = (0,0,0,0)
		_NormalMapMoveSpeed1("Normalmap 1 move speed", Float) = 0
		_Heightmap("Height map", 2D) = "black" {}

		[Header(Distortions 2)]
		_NormalMap2("Normalmap 2", 2D) = "white" {}
		_NormalMapMoveDir2("Normalmap 2 move dir", Vector) = (0,0,0,0)
		_NormalMapMoveSpeed2("Normalmap 2 move speed", Float) = 0
		_Heightmap2("Height map", 2D) = "black" {}

		[Header(Distortion settings)]
		_NormalMapBias("Normalmap Strength", Range(0.0,1.0)) = 0.5
		_HeightmapStrength("Heightmap strength", Range(0,5)) = 0
		_HeightmapFoamColor("Heightmap foam color", Color) = (1,1,1,1)
		_HeightMapFoamStrength("Heightmap foam strength", Range(0,2)) = 1

		// Fog
		[Header(Water fog)]
		_WaterFogColor("Water Fog Color", Color) = (0, 0, 0, 0)
		_WaterFogDensity("Water Fog Density", Range(0, 10)) = 0.15

		// Refraction
		[Header(Refraction)]
		_RefractionStrength("Refraction Strength", Range(0, 1)) = 0.25

		// Subsurface scattering
		[Header(Subsurface scattering)]
		_SSSPower("Power", Float) = 0

		// Wave Crest foam
		[Header(Wave crest foam)]
		_FoamSpread("Foam Scale", Range(0.1, 3.0)) = 2.43

		// Intersection foam
		[Header(Intersection foam)]
		_IntersectionFoamDensity("Intersection Foam Range", Range(0, 10)) = 0.15
		_IntersectionFoamRamp("Intersection Foam Ramp", 2D) = "black" {}
		_IntersectionFoamColor("Intersection foam Color", Color) = (1,1,1,1)


		// Vertex waves
		[Header(Base Wave)]
		_WaveLength1("Wavelength",  Float) = 0.1
		_Amplitude1("Amplitude", Float) = 0.001
		_Speed1("Speed", Float) = 1
		_DirectionX1("Direction X", Range(-1,1)) = 1
		_DirectionY1("Direction Y", Range(-1,1)) = 1
		_Steepness1("Steepness", Range(0,10)) = 0.1
		_FadeSpeed1("FadeSpeed", Float) = 1.0

		[Header(Additional Waves)]
		[Header(Wave 2)]
		[Toggle(WAVE2)] _Wave2Enabled("Enabled", Float) = 0
		_WaveLength2("Wavelength",  Float) = 0.1
		_Amplitude2("Amplitude", Float) = 0.001
		_Speed2("Speed", Float) = 1
		_DirectionX2("Direction X", Range(-1,1)) = 1
		_DirectionY2("Direction Y", Range(-1,1)) = 1
		_Steepness2("Steepness", Range(0,10)) = 0.1
		_FadeSpeed2("FadeSpeed", Float) = 1.0

		[Header(Wave 3)]
		[Toggle(WAVE3)] _Wave3Enabled("Enabled", Float) = 0
		_WaveLength3("Wavelength",  Float) = 0.1
		_Amplitude3("Amplitude", Float) = 0.001
		_Speed3("Speed", Float) = 1
		_DirectionX3("Direction X", Range(-1,1)) = 1
		_DirectionY3("Direction Y", Range(-1,1)) = 1
		_Steepness3("Steepness", Range(0,10)) = 0.1
		_FadeSpeed3("FadeSpeed", Float) = 1.0

		[Header(Wave 4)]
		[Toggle(WAVE4)] _Wave4Enabled("Enabled", Float) = 0
		_WaveLength4("Wavelength",  Float) = 0.1
		_Amplitude4("Amplitude", Float) = 0.001
		_Speed4("Speed", Float) = 1
		_DirectionX4("Direction X", Range(-1,1)) = 1
		_DirectionY4("Direction Y", Range(-1,1)) = 1
		_Steepness4("Steepness", Range(0,10)) = 0.1
		_FadeSpeed4("FadeSpeed", Float) = 1.0

		[Header(Wave 5)]
		[Toggle(WAVE5)] _Wave5Enabled("Enabled", Float) = 0
		_WaveLength5("Wavelength",  Float) = 0.1
		_Amplitude5("Amplitude", Float) = 0.001
		_Speed5("Speed", Float) = 1
		_DirectionX5("Direction X", Range(-1,1)) = 1
		_DirectionY5("Direction Y", Range(-1,1)) = 1
		_Steepness5("Steepness", Range(0,10)) = 0.1
		_FadeSpeed5("FadeSpeed", Float) = 1.0
	}
	SubShader{
		
		// ------- PASS 1 ---------------
		
		ZWrite on
		Cull back
		Colormask 0
		Lighting Off

		CGPROGRAM

		#pragma surface surf Standard vertex:vert nometa
		#include "UnityCG.cginc"
		#include "WaterIncludes.cginc"
		#pragma shader_feature WAVE2
		#pragma shader_feature WAVE3
		#pragma shader_feature WAVE4
		#pragma shader_feature WAVE5

		struct Input {
			float2 uv_MainTex;
		};
		
		// Height map
		sampler2D _Heightmap;
		sampler2D _Heightmap2;
		float _HeightmapStrength;

		half4 _NormalMapMoveDir1;
		half4 _NormalMapMoveDir2;
		half _NormalMapMoveSpeed1;
		half _NormalMapMoveSpeed2;

		void vert(inout appdata_full v) {
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex);

			float3 wavePointSum = worldPos + WavePointSum(worldPos).xyz;
			
			// Add heightmap value to pos.y
			float heightAdd1 = tex2Dlod(_Heightmap, float4(v.texcoord.xy + _NormalMapMoveDir1.xy * _NormalMapMoveSpeed1 * _Time.x, 0, 0)).r;
			float heightAdd2 = tex2Dlod(_Heightmap2, float4(v.texcoord.xy + _NormalMapMoveDir2.xy * _NormalMapMoveSpeed2 * _Time.x, 0, 0)).r;

			heightAdd1 = (heightAdd1 - 0.5) * 2;
			heightAdd2 = (heightAdd2 - 0.5) * 2;

			float heightAddCombined = (heightAdd1 + heightAdd2) / 2;

			wavePointSum.y += (heightAddCombined * _HeightmapStrength);

			// Final vertex output
			v.vertex.xyz = mul(unity_WorldToObject, float4(wavePointSum, 1));
		}
		
		void surf(Input IN, inout SurfaceOutputStandard o) { }

		ENDCG
		
		// ------- END PASS 1 ---------------

		GrabPass{ "_WaterBackground" }

		// ------- PASS 2 ---------------
		
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }

		ZWrite off
		Cull back
		Blend SrcAlpha OneMinusSrcAlpha
		Colormask RGBA

		CGPROGRAM

		#pragma surface surf StandardTranslucent vertex:vert alpha:fade finalcolor:ResetAlpha nometa novertexlights noforwardadd 
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "WaterIncludes.cginc"
		#pragma target 3.0
		#pragma shader_feature WAVE2
		#pragma shader_feature WAVE3
		#pragma shader_feature WAVE4
		#pragma shader_feature WAVE5

		struct Input {
			float2 uv_NormalMap1;
			float2 uv_NormalMap2;
			float4 screenPos;
			float crestFactor;
			float3 worldDirNormal;
		};

		// Normal maps
		sampler2D _NormalMap1;
		sampler2D _NormalMap2;
		half4 _NormalMapMoveDir1;
		half _NormalMapMoveSpeed1;
		half4 _NormalMapMoveDir2;
		half _NormalMapMoveSpeed2;
		half _NormalMapBias;

		// Color
		fixed4 _Color;
		fixed4 _SSSColor;

		// Other
		half _SmoothNess;
        fixed4 _WaveFoamDir;

		// SubSurface Scattering
		half _SSSPower;

		// Height map
		sampler2D _Heightmap;
		sampler2D _Heightmap2;
		half _HeightmapStrength;
		fixed3 _HeightmapFoamColor;
		half _HeightMapFoamStrength;

		void vert(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
			float4 wavePointSum = WavePointSum(worldPos);
			float3 pos = worldPos + wavePointSum.xyz;

			// This is to avoid z fighting between the two passes. Can probably be done in a better way.
			pos.y += 0.001;

			float heightAdd1 = tex2Dlod(_Heightmap, float4(v.texcoord.xy + _NormalMapMoveDir1.xy * _NormalMapMoveSpeed1 * _Time.x, 0, 0)).r;
			float heightAdd2 = tex2Dlod(_Heightmap2, float4(v.texcoord.xy + _NormalMapMoveDir2.xy * _NormalMapMoveSpeed2 * _Time.x, 0, 0)).r;

			heightAdd1 = (heightAdd1 - 0.5) * 2;
			heightAdd2 = (heightAdd2 - 0.5) * 2;

			float heightAddCombined = (heightAdd1 + heightAdd2) / 2;

			pos.y += (heightAddCombined * _HeightmapStrength);

			float3 waveNormalSum = WaveNormalSum(pos);

			o.crestFactor = wavePointSum.w;
            o.worldDirNormal = waveNormalSum.xyz;
            
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

			float SSS = NdotL * VdotN * VdotL * _SSSPower;

			// Final add
			pbr.rgb = pbr.rgb + SSS * _Color;
			return pbr;
		}

		void LightingStandardTranslucent_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
			LightingStandard_GI(s, data, gi);
		}

		void ResetAlpha(Input IN, SurfaceOutputStandard o, inout fixed4 color) {
			color.a = 1;
		}
		
		void surf(Input IN, inout SurfaceOutputStandard o) {
            float noFoam = saturate(dot(IN.worldDirNormal, _WaveFoamDir));

			// ---------- Normal maps ----------
			float3 waterNormal1 = normalize(UnpackNormal(tex2D(_NormalMap1, IN.uv_NormalMap1 + _NormalMapMoveDir1.xy * _NormalMapMoveSpeed1 * _Time.x)));
			float3 waterNormal2 = normalize(UnpackNormal(tex2D(_NormalMap2, IN.uv_NormalMap2 + _NormalMapMoveDir2.xy * _NormalMapMoveSpeed2 * _Time.x)));
			float3 totalWaterNormal = normalize(float3(waterNormal1.xy + waterNormal2.xy, waterNormal1.z));
			totalWaterNormal.xy *= _NormalMapBias;

			o.Normal = totalWaterNormal;

			// ---------- Height map foam ----------
			float heightMapAdd1 = pow(tex2D(_Heightmap, IN.uv_NormalMap1 + _NormalMapMoveDir1.xy * _NormalMapMoveSpeed1 * _Time.x).r, 4);
			float heightMapAdd2 = pow(tex2D(_Heightmap2, IN.uv_NormalMap2 + _NormalMapMoveDir2.xy * _NormalMapMoveSpeed2 * _Time.x).r, 4);

			float totalHeightAdd = ((heightMapAdd1 + heightMapAdd2) / 2) * _HeightMapFoamStrength;


			float3 foam = ((totalHeightAdd + pow(IN.crestFactor, 1)) / 2) * (1 - noFoam);
            
			float alpha = saturate(_Color.a + foam);
            
			o.Albedo =  _Color + foam;
			o.Smoothness = saturate( _SmoothNess - foam);
			o.Metallic = 0.0;
			o.Alpha = alpha;
			o.Emission = ColorBelowWater(IN.screenPos, o.Normal) * (1 - alpha);
		}

		ENDCG


	}
}