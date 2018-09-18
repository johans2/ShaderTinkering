﻿Shader "Custom/Water"
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

				//float L = 0.1;
				float frequency = 2 / _L;
				float amp = 0.001;
				float2 direction = float2(0.5,0.5);

				float phaseConstantSpeed = _Speed * (2 / _L);

				float waveX = _Amplitude * sin(direction.x * IN.uv.x * frequency + _Time.x * phaseConstantSpeed);
				float waveZ = _Amplitude * sin(direction.y * IN.uv.y * frequency + _Time.x * phaseConstantSpeed);

				float totalWave = waveX + waveZ;

				IN.position.z = totalWave;


				o.vertex = UnityObjectToClipPos(IN.position);
				o.uv = TRANSFORM_TEX(IN.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
