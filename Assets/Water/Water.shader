Shader "Custom/Water"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_L("Wavelength",  Float) = 0.1
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
			float _L; 
			float _Amplitude;
			float _Speed;
			
			// https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
			v2f vert (vertData IN)
			{
				v2f o;

				float frequency = 2 / _L;
				float phaseConstantSpeed = _Speed * (2 / _L);

				// Wave 1

				float2 direction1 = normalize(float2(1,1));
				/*
				float wave1 = _Amplitude * sin(dot(direction1, float2(IN.position.x, IN.position.y)) * frequency + _Time.x * phaseConstantSpeed);

				float normal1X = frequency * direction1.x * _Amplitude * cos(dot(direction1, float2(IN.position.x, IN.position.y)) * frequency + _Time.x * phaseConstantSpeed);
				float normal1Y = frequency * direction1.y * _Amplitude * cos(dot(direction1, float2(IN.position.x, IN.position.y)) * frequency + _Time.x * phaseConstantSpeed);
				float3 normal1 = float3(-normal1X, -normal1Y, 1);
				*/
				float Q = 1;

				float fi = _Time.x  * phaseConstantSpeed;
				float dirDotPos = dot(direction1, float2(IN.position.x, IN.position.y));

				float waveGretzX = IN.position.x + Q * _Amplitude * direction1.x * cos(frequency * dirDotPos + fi);
				float waveGretzY = IN.position.y + Q * _Amplitude * direction1.y * cos(frequency * dirDotPos + fi);
				float waveGretzZ = _Amplitude * sin(frequency * dirDotPos + fi);

				/*
				// Wave 2

				float2 direction2 = normalize(float2(-1, 1));
				float wave2 = _Amplitude * sin(dot(direction2, float2(IN.position.x, IN.position.y)) * frequency + _Time.x * phaseConstantSpeed);

				float normal2X = frequency * direction2.x * _Amplitude * cos(dot(direction2, float2(IN.position.x, IN.position.y)) * frequency + _Time.x * phaseConstantSpeed);
				float normal2Y = frequency * direction2.y * _Amplitude * cos(dot(direction2, float2(IN.position.x, IN.position.y)) * frequency + _Time.x * phaseConstantSpeed);
				float3 normal2 = float3(-normal2X, -normal2Y, 1);
				*/
				IN.position = float3(waveGretzX, waveGretzY, waveGretzZ);

				//IN.position.z += wave1; // +wave2;

				//o.normal = normal1; // +normal2;
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
			ENDCG
		}
	}
}
