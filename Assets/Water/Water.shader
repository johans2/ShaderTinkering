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
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull off

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
			
			// https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
			v2f vert (vertData IN)
			{
				v2f o;
				// Wave directions
				float2 direction1 = normalize(float2(1,1));
				float2 direction2 = normalize(float2(-1,1));

				// Wave points
				float3 wavePoint1 = WavePoint(IN.position.xy, _Amplitude, _WaveLength, _Speed, direction1, 0.8);
				float3 wavePoint2 = WavePoint(IN.position.xy, _Amplitude, _WaveLength, _Speed, direction2, 0.8);

				float3 totalWave = float3(IN.position.x, IN.position.y, 0) + wavePoint1 + wavePoint2;

				// Wave normals
				float3 waveNormal1 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction1, 0.8);
				float3 waveNormal2 = WaveNormal(totalWave, _Amplitude, _WaveLength, _Speed, direction2, 0.8);

				float3 totalNormal = waveNormal1 + waveNormal2;
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
				col = fixed4(0, 0, 0, 1);


				col.r = i.normal.x * 0.5 + 0.5;
				col.g = i.normal.y * 0.5 + 0.5;
				col.b = i.normal.z * 0.5 + 0.5;
				
				return col;
			}

			ENDCG
		}
	}
}
