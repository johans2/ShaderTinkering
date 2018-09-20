Shader "Custom/Water"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_WaveLength("Wavelength",  Float) = 0.1
		_Amplitude("Amplitude", Float) = 0.001
		_Speed("Speed", Float) = 1
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100
		Cull back
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "WaterIncludes.cginc"

			struct vertData {
				float3 position : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;

			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _WaveLength;
			float _Amplitude;
			float _Speed;

			fixed4 _LightColor0;
			
			// https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
			v2f vert (vertData IN)
			{
				v2f o;
				// Wave directions
				float2 direction1 = normalize(float2(1,0));
				float2 direction2 = normalize(float2(0,1));
				float2 direction3 = normalize(float2(0.3, 0.4));

				// Wave points
				float3 wavePoint1 = WavePoint(IN.position.xy, _Amplitude *1.2, _WaveLength *2, _Speed, direction1, 0.2);
				float3 wavePoint2 = WavePoint(IN.position.xy, _Amplitude, _WaveLength, _Speed * 0.2, direction2, 0.6);

				float3 wavePoint3 = WavePoint(IN.position.xy, _Amplitude * 0.5, _WaveLength * 0.5, _Speed * 2, direction3, 0.6);

				float3 totalWave = float3(IN.position.x, IN.position.y, 0) + wavePoint1 + wavePoint2 + wavePoint3;

				// Wave normals
				float3 waveNormal1 = WaveNormal(totalWave, _Amplitude*1.2, _WaveLength *2, _Speed, direction1, 0.2);
				float3 waveNormal2 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed* 0.2, direction2, 0.6);
				float3 waveNormal3 = WaveNormal(totalWave, _Amplitude* 0.5, _WaveLength* 0.5, _Speed* 2, direction3, 0.6);

				float3 totalNormal = waveNormal1 + waveNormal2 + waveNormal3;
				totalNormal.x = -totalNormal.x;
				totalNormal.y = -totalNormal.y;
				totalNormal.z = 1 - totalNormal.z;

				totalNormal = normalize(totalNormal);

				o.vertex = UnityObjectToClipPos(totalWave);
				o.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				o.normal = totalNormal;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				
				// Light direction
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				// Camera direction
				half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.vertex.xyz);

				// -------------------- DIFFUSE LIGHT ----------------------

				// This will be light added to all parts of the obejct, including dark ones.
				half3 indirectDiffuse = unity_AmbientSky;

				// Compute the diffuse lighting
				half NdotL = max(0., dot(i.normal, lightDir));

				// Diffuse based on light source
				half3 directDiffuse = _LightColor0;

				// Light = direct + indirect;
				half3 diffuse = lerp(directDiffuse, indirectDiffuse, NdotL);

				col.a = 0.5;
				col.rgb *= diffuse;

				return col;
			}

			ENDCG
		}
	}
}
