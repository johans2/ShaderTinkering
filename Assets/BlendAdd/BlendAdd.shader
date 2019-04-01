Shader "Unlit/BlendAdd"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D) = "black" {}
		_Mask("Mask Texture", 2D) = "white" {}
		_Color("Color tint", Color) = (1,1,1,1)

		_Speed1("Speed 1", Float) = 1
		_Speed2("Speed 2", Float) = 1
		_Speed3("Speed 3", Float) = 1
	}
	SubShader
	{
		Tags { "Queue"="Transparent"  "RenderType"="Transparent" }
		
		ZWrite Off
		Blend One OneMinusSrcAlpha
		//Blend SrcAlpha OneMinusSrcAlpha


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
			
			float _Speed1;
			float _Speed2;
			float _Speed3;

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
				float2 uv1 = i.uv;
				uv1.xy -= _Time.x * _Speed1;
				float noise1 = tex2D(_NoiseTex, uv1).a;

				// Second noise sample
				float2 uv2 = i.uv * 0.5;
				uv2.xy -= _Time.x * _Speed2;
				float noise2 = tex2D(_NoiseTex, uv2).a;

				// Third noise sample
				float2 uv3 = i.uv * 2;
				uv3.xy -= _Time.x * _Speed3;
				float noise3 = tex2D(_NoiseTex, uv3).a;

				// Final noise
				float finalNoise = saturate(noise1 * noise2 * noise3 * 3);
				
				half4 mask = tex2D(_Mask, i.uv);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);


				float4 final = i.color.a * mask.r * finalNoise * _Color;

				
				return final;
			}
			ENDCG
		}
	}
}
