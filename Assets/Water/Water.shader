Shader "Custom/Water"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

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
			
			// https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html
			v2f vert (vertData IN)
			{
				v2f o;

				float L = 0.1;
				float waveLength = 2 / L;


				float amp = 0.001;
				float2 direction = float2(0.5,0.5);
				float speed = 20;

				float phaseSpeed = speed * (2 / L);

				float totalWave = amp * sin( /*direction * */IN.uv.x * waveLength + _Time * speed);

				IN.position.z += totalWave;


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
