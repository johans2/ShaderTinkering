Shader "Unlit/BlendAdd"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D) = "black" {}
		_Mask("Mask Texture", 2D) = "white" {}
		_Color("Color tint", Color) = (1,1,1,1)


		_UVMultiplier1("UV multiplier 1", Float) = 1
		_UVMultiplier2("UV multiplier 2", Float) = 1
		_UVMultiplier3("UV multiplier 3", Float) = 1
		_UVMultiplier4("UV multiplier 4", Float) = 1
		_UVMultiplier5("UV multiplier 5", Float) = 1
		_UVMultiplier6("UV multiplier 6", Float) = 1
		_UVMultiplier7("UV multiplier 7", Float) = 1


		_Speed1("Speed 1", Float) = 1
		_Speed2("Speed 2", Float) = 1
		_Speed3("Speed 3", Float) = 1
		_Speed4("Speed 4", Float) = 1
		_Speed5("Speed 5", Float) = 1
		_Speed6("Speed 6", Float) = 1
		_Speed7("Speed 7", Float) = 1
	}
	SubShader
	{
		Tags { "Queue"="Transparent"  "RenderType"="Transparent" }
		
		ZWrite Off
		Blend One OneMinusSrcAlpha
		
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 color : COLOR;
			};

			sampler2D _MainTex;
			sampler2D _NoiseTex;
			sampler2D _Mask;

			float4 _MainTex_ST;
			float4 _NoiseTex_ST;
			float4 _Mask_ST;
			float4 _Color;
			

			float _UVMultiplier1;
			float _UVMultiplier2;
			float _UVMultiplier3;
			float _UVMultiplier4;
			float _UVMultiplier5;
			float _UVMultiplier6;
			float _UVMultiplier7;


			float _Speed1;
			float _Speed2;
			float _Speed3;
			float _Speed4;
			float _Speed5;
			float _Speed6;
			float _Speed7;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				// First noise sample
				float2 uv1 = i.uv * _UVMultiplier1;
				uv1.xy -= _Time.x * _Speed1;
				float noise1 = tex2D(_NoiseTex, uv1).a;

				// Second noise sample
				float2 uv2 = i.uv * _UVMultiplier2;
				uv2.xy -= _Time.x * _Speed2;
				float noise2 = tex2D(_NoiseTex, uv2).a;

				// Third noise sample
				float2 uv3 = i.uv * _UVMultiplier3;
				uv3.xy -= _Time.x * _Speed3;
				float noise3 = tex2D(_NoiseTex, uv3).a;

				// 4th noise sample
				float2 uv4 = i.uv * _UVMultiplier4;
				uv4.xy -= _Time.x * _Speed4;
				float noise4 = tex2D(_NoiseTex, uv4).a;

				// 5th noise sample
				float2 uv5 = i.uv * _UVMultiplier5;
				uv5.xy -= _Time.x * _Speed5;
				float noise5 = tex2D(_NoiseTex, uv5).a;

				// 6th noise sample
				float2 uv6 = i.uv * _UVMultiplier6;
				uv6.xy -= _Time.x * _Speed6;
				float noise6 = tex2D(_NoiseTex, uv6).a;

				// 7th noise sample
				float2 uv7 = i.uv * _UVMultiplier7;
				uv7.xy -= _Time.x * _Speed7;
				float noise7 = tex2D(_NoiseTex, uv7).a;

				// Final noise
				float finalNoise = noise1;
				
				finalNoise *= noise2;
				finalNoise *= 2;
				finalNoise = saturate(finalNoise);

				finalNoise *= noise3;
				finalNoise *= 2;
				finalNoise = saturate(finalNoise);
				
				finalNoise *= noise4;
				finalNoise *= 2;
				finalNoise = saturate(finalNoise);
				
				finalNoise *= noise5;
				finalNoise *= 2;
				finalNoise = saturate(finalNoise);
				
				finalNoise *= noise6;
				finalNoise *= 2;
				finalNoise = saturate(finalNoise);

				finalNoise *= noise7;
				finalNoise *= 2;
				
				finalNoise = saturate(finalNoise);

				half4 mask = tex2D(_Mask, i.uv);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);


				float4 final = mask.r * finalNoise * _Color;

				
				return final;
			}
			ENDCG
		}
	}
}
