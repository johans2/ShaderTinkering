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

				float frequency = 2 / _WaveLength;
				float phaseConstantSpeed = _Speed * (2 / _WaveLength);

				// Wave 1

				float2 direction1 = normalize(float2(1,1));
				float Q = 1;

				float fi = _Time.x  * phaseConstantSpeed;
				float dirDotPos = dot(direction1, float2(IN.position.x, IN.position.y));

				float waveGretsX = IN.position.x + Q * _Amplitude * direction1.x * cos(frequency * dirDotPos + fi);
				float waveGretsY = IN.position.y + Q * _Amplitude * direction1.y * cos(frequency * dirDotPos + fi);
				float waveGretsZ = _Amplitude * sin(frequency * dirDotPos + fi);


				float3 wavePoint = WavePoint(IN.position.xy, _Amplitude, _WaveLength, _Speed, direction1, 0.8);

				IN.position = wavePoint; //float3(waveGretsX, waveGretsY, waveGretsZ);

				o.vertex = UnityObjectToClipPos(IN.position);
				o.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				
				col.x = i.normal.x * 0.5 + 0.5;
				col.y = i.normal.y * 0.5 + 0.5;
				col.z = i.normal.z * 0.5 + 0.5;
				
				return col;
			}

			float3 WavePoint(float2 position, float wavelength, float speed, float2 direction, float steepness) {
				float frequency = 2 / wavelength;
				float phaseConstantSpeed = speed * (2 / wavelength);

				float fi = _Time.x  * phaseConstantSpeed;
				float dirDotPos = dot(direction, position);

				float waveGretsX = position.x + steepness * _Amplitude * direction.x * cos(frequency * dirDotPos + fi);
				float waveGretsY = position.y + steepness * _Amplitude * direction.y * cos(frequency * dirDotPos + fi);
				float waveGretsZ = _Amplitude * sin(frequency * dirDotPos + fi);

				return float3(waveGretsX, waveGretsY, waveGretsZ);
			}


			ENDCG
		}
	}
}
