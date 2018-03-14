// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/GrassGeometryShader" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_TrampleTex("Trample Texture", 2D) = "white" {}
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_GrassHeight("Grass Height", Float) = 0.25
		_GrassWidth("Grass Width", Float) = 0.25
		_WindStrength("Wind strength", Float) = 1
		_WindSpeed("Wind speed", Float) = 1
	}
	SubShader{
			Pass{
				Tags { "RenderType" = "Transparent" }
				LOD 200
				CULL back

				CGPROGRAM

				// Use shader model 4.0 target, need geometry shader support
				#include "UnityCG.cginc"
				#include "TexturePackingUtils.cginc"
				#pragma target 5.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma geometry geom

				sampler2D _MainTex;
				sampler2D _TrampleTex;

				struct v2g {
					float4 pos : SV_POSITION;
					float3 norm : NORMAL;
					float2 uv : TEXCOORD0;
				};

				struct g2f {
					float4 pos : SV_POSITION;
					float3 norm : NORMAL;
					float2 uv : TEXCOORD0;
				};
		


				half _Glossiness;
				half _Metallic;
				fixed4 _Color;
				half _GrassHeight;
				half _GrassWidth;
				half _WindStrength;
				half _WindSpeed;
				const float PI = 3.14159265f;

				v2g vert(appdata_full v) {
					
					v2g OUT;
					OUT.pos = v.vertex;
					OUT.norm = v.normal;
					OUT.uv = v.texcoord;

					return OUT;
				}

				void buildQuad(inout TriangleStream<g2f> triStream, float3 v0, float3 v1, float3 faceNormal, float3 quadOffset) {

					g2f OUT;

					// 1
					OUT.pos = UnityObjectToClipPos(v1 + quadOffset);
					OUT.norm = faceNormal;
					OUT.uv = float2(1, 1);
					triStream.Append(OUT);

					// 2
					OUT.pos = UnityObjectToClipPos(v0 + quadOffset);
					OUT.norm = faceNormal;
					OUT.uv = float2(1, 0);
					triStream.Append(OUT);

					// 3
					OUT.pos = UnityObjectToClipPos(v1 - quadOffset);
					OUT.norm = faceNormal;
					OUT.uv = float2(0, 1);
					triStream.Append(OUT);

					// 4
					OUT.pos = UnityObjectToClipPos(v0 - quadOffset);
					OUT.norm = faceNormal;
					OUT.uv = float2(0, 0);
					triStream.Append(OUT);

					triStream.RestartStrip();
				}

				[maxvertexcount(33)]
				void geom(point v2g IN[1], inout TriangleStream<g2f> triStream) {
					float3 lightPosition = _WorldSpaceLightPos0;

					float3 perpendicularAngle = float3(1, 0, 0);
					float3 faceNormal = _WorldSpaceCameraPos - IN[0].pos.xyz;

					// Sample and unpack the trample values
					float4 trample = tex2Dlod(_TrampleTex, float4(1 - (IN[0].pos.x / 100 + 0.5), 1 - (IN[0].pos.z / 100 + 0.5),0,0));
					trample = UnPackFloat4(trample);

					// Calculate the two base vertices.
					float3 v0 = IN[0].pos.xyz;
					float3 v1 = IN[0].pos.xyz + IN[0].norm * _GrassHeight + trample;
					
					// Add wind.
					half time = _Time.x * _WindSpeed;
					float3 wind = float3(sin(time + v0.x) + sin(time + v0.z * 2 + cos(time + v0.x)), 0 , cos(time + v0.x * 2) + cos(time + v0.z));
					v1 += wind * _WindStrength;


					// Build the quads
					float3 crossA = IN[0].norm;
					float3 crossB = crossA + float3(1, 0, 0);
					float3 crossC = crossA + float3(0, 0, 1);

					// This creates the base vectors from which the quads are generated.
					// Perpendicular vector.
					float3 pVector = normalize( cross(crossA, crossB)) * _GrassWidth;

					// Horizontal vector.
					float3 hVector = normalize(cross(crossA, crossC)) * _GrassWidth;

					// Middle vector.
					float3 mVector = normalize(pVector + hVector) * _GrassWidth;

					// Negative middle vector.
					float3 mNegVector = normalize(pVector - hVector) * _GrassWidth;

					// Build the grass quads.
					buildQuad(triStream, v0, v1, faceNormal, pVector);
					buildQuad(triStream, v0, v1, faceNormal, hVector);
					buildQuad(triStream, v0, v1, faceNormal, mVector);
					buildQuad(triStream, v0, v1, faceNormal, mNegVector);
					
				}

				half4 frag(g2f IN) : COLOR {
					float4 c = tex2D(_MainTex, IN.uv);
					clip(c.a - 0.1);
					return c;
				}
				ENDCG
			}
		}
}
