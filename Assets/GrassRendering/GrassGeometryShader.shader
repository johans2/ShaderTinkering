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
				CULL off

				CGPROGRAM

				// Use shader model 4.0 target, need geometry shader support
				#include "UnityCG.cginc"
				#pragma target 4.0
				#pragma vertex vert
				#pragma fragment frag
				#pragma geometry geom

				sampler2D _MainTex;
				sampler2D _TrampleTex;

				struct v2g {
					float4 pos : SV_POSITION;
					float3 norm : NORMAL;
					float2 uv : TEXCOORD0;
					float3 color : TEXCOORD1;
				};

				struct g2f {
					float4 pos : SV_POSITION;
					float3 norm : NORMAL;
					float2 uv : TEXCOORD0;
					float3 diffuseColor : TEXCOORD1;
				};
		

				half _Glossiness;
				half _Metallic;
				fixed4 _Color;
				half _GrassHeight;
				half _GrassWidth;
				half _WindStrength;
				half _WindSpeed;

				v2g vert(appdata_full v) {
					float3 v0 = v.vertex.xyz;

					v2g OUT;
					OUT.pos = v.vertex;
					OUT.norm = v.normal;
					OUT.uv = v.texcoord;
					OUT.color = tex2Dlod(_MainTex, v.texcoord).rgb;

					return OUT;
				}

				[maxvertexcount(33)]
				void geom(point v2g IN[1], inout TriangleStream<g2f> triStream) {
					float3 lightPosition = _WorldSpaceLightPos0;

					float3 perpendicularAngle = float3(1, 0, 0);
					float3 faceNormal = cross(perpendicularAngle, IN[0].norm);

					float3 v0 = IN[0].pos.xyz;
					float3 v1 = IN[0].pos.xyz + IN[0].norm * _GrassHeight;

					half time = _Time.x * _WindSpeed;
					float3 wind = float3(sin(time + v0.x) + sin(time + v0.z * 2 + cos(time + v0.x)), 0 , cos(time + v0.x * 2) + cos(time + v0.z));
					v1 += wind * _WindStrength;


					float3 crossA = IN[0].norm;
					float3 crossB = crossA + float3(1, 0, 0);
					float3 crossC = crossA + float3(0, 0, 1);

					// This creates the base vectors from which the quads are generated.
					// Perpendicular vector.
					float3 pVector = normalize( cross(crossA, crossB)) * _GrassHeight;

					// Horizontal vector.
					float3 hVector = normalize(cross(crossA, crossC)) * _GrassHeight;

					// Middle vector.
					float3 mVector = normalize(pVector + hVector) * _GrassHeight;

					// Negative middle vector.
					float3 mNegVector = normalize(pVector - hVector) * _GrassHeight;

					float3 color = IN[0].color;
					
					g2f OUT;

					// Plane 1, Quad 1
					// Mid BOTTOM
					OUT.pos = UnityObjectToClipPos(v0);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 0);
					triStream.Append(OUT);

					// Mid TOP
					OUT.pos = UnityObjectToClipPos(v1);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 1);
					triStream.Append(OUT);

					// c
					OUT.pos = UnityObjectToClipPos(v1 + pVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(1, 1);
					triStream.Append(OUT);

					// a
					OUT.pos = UnityObjectToClipPos(v0 + pVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(1, 0);
					triStream.Append(OUT);

					// Plane 1, Quad 2
					// Mid BOTTOM
					OUT.pos = UnityObjectToClipPos(v0);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 0);
					triStream.Append(OUT);

					// Mid TOP
					OUT.pos = UnityObjectToClipPos(v1);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 1);
					triStream.Append(OUT);

					// d
					OUT.pos = UnityObjectToClipPos(v1 - pVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 1);
					triStream.Append(OUT);

					// b
					OUT.pos = UnityObjectToClipPos(v0 - pVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0,0);
					triStream.Append(OUT);

					// Plane 2, quad 1
					// Mid BOTTOM
					OUT.pos = UnityObjectToClipPos(v0);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 0);
					triStream.Append(OUT);

					// Mid TOP
					OUT.pos = UnityObjectToClipPos(v1);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 1);
					triStream.Append(OUT);


					// j
					OUT.pos = UnityObjectToClipPos(v1 + hVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(1, 1);
					triStream.Append(OUT);

					// h
					OUT.pos = UnityObjectToClipPos(v0 + hVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(1, 0);
					triStream.Append(OUT);

					// Plane 2, quad 2
					// Mid BOTTOM
					OUT.pos = UnityObjectToClipPos(v0);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 0);
					triStream.Append(OUT);

					// Mid TOP
					OUT.pos = UnityObjectToClipPos(v1);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 1);
					triStream.Append(OUT);

					// i
					OUT.pos = UnityObjectToClipPos(v1 - hVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 1);
					triStream.Append(OUT);

					// g
					OUT.pos = UnityObjectToClipPos(v0 - hVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 0);
					triStream.Append(OUT);

					// Plane 3, quad 1
					// Mid BOTTOM
					OUT.pos = UnityObjectToClipPos(v0);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 0);
					triStream.Append(OUT);

					// Mid TOP
					OUT.pos = UnityObjectToClipPos(v1);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 1);
					triStream.Append(OUT);

					// i
					OUT.pos = UnityObjectToClipPos(v1 + mVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 1);
					triStream.Append(OUT);

					// g
					OUT.pos = UnityObjectToClipPos(v0 + mVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 0);
					triStream.Append(OUT);

					// Plane 3, quad 2
					// Mid BOTTOM
					OUT.pos = UnityObjectToClipPos(v0);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 0);
					triStream.Append(OUT);

					// Mid TOP
					OUT.pos = UnityObjectToClipPos(v1);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 1);
					triStream.Append(OUT);

					// i
					OUT.pos = UnityObjectToClipPos(v1 - mVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 1);
					triStream.Append(OUT);

					// g
					OUT.pos = UnityObjectToClipPos(v0 - mVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 0);
					triStream.Append(OUT);
					
					// Plane 4, quad 1
					// Mid BOTTOM
					OUT.pos = UnityObjectToClipPos(v0);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 0);
					triStream.Append(OUT);

					// Mid TOP
					OUT.pos = UnityObjectToClipPos(v1);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 1);
					triStream.Append(OUT);

					// i
					OUT.pos = UnityObjectToClipPos(v1 + mNegVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 1);
					triStream.Append(OUT);

					// g
					OUT.pos = UnityObjectToClipPos(v0 + mNegVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 0);
					triStream.Append(OUT);
					
					// Plane 4, quad 1
					// Mid BOTTOM
					OUT.pos = UnityObjectToClipPos(v0);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 0);
					triStream.Append(OUT);

					// Mid TOP
					OUT.pos = UnityObjectToClipPos(v1);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 1);
					triStream.Append(OUT);

					// i
					OUT.pos = UnityObjectToClipPos(v1 - mNegVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 1);
					triStream.Append(OUT);

					// g
					OUT.pos = UnityObjectToClipPos(v0 - mNegVector);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0, 0);
					triStream.Append(OUT);
					

					// Lastly we need to loop back to complete the mesh
					// Mid BOTTOM
					OUT.pos = UnityObjectToClipPos(v0);
					OUT.norm = faceNormal;
					OUT.diffuseColor = color;
					OUT.uv = float2(0.5, 0);
					triStream.Append(OUT);

				}
		
				half4 frag(g2f IN) : COLOR {
					float4 c = tex2D(_MainTex, IN.uv);
					float4 tc = tex2D(_TrampleTex, IN.uv);
					clip(c.a - 0.1);
					return c;
				}
				ENDCG
			}
		}
}
