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
				float2 direction = normalize(float2(0.1,0.1));

				float phaseConstantSpeed = _Speed * (2 / _L);

				float waveX = _Amplitude * sin(direction.x * IN.position.x * frequency + _Time.x * phaseConstantSpeed);
				float waveZ = _Amplitude * sin(direction.y * IN.position.y * frequency + _Time.x * phaseConstantSpeed);

				float normalX = frequency * direction.x * _Amplitude * cos(dot(direction, float2(IN.position.x, IN.position.y)) * frequency + _Time.x * phaseConstantSpeed);
				float normalY = frequency * direction.y * _Amplitude * cos(dot(direction, float2(IN.position.x, IN.position.y)) * frequency + _Time.x * phaseConstantSpeed);

				float3 normal = normalize(float3(-normalX, -normalY, 1));

				float totalWave = waveX + waveZ;

				IN.position.z += totalWave;

				o.normal = normal;
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
