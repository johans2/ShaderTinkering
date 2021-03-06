﻿Shader "Custom/ParticlesComputed" {
	Properties {
		_ParticleSize("ParticleSize", Float) = 0.01
		_MainTex("Particle texture", 2D) = "white" {}
	}

	SubShader {
		Pass {
			Tags {"Queue" = "Transparent" "RenderType" = "Transparent" }
			LOD 200
			Cull off
			ZWrite off
		
			Blend SrcAlpha OneMinusSrcAlpha
			
			BlendOp Add


			//Blend SrcAlpha One
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"

			// Use shader model 5.0 target, to be able to use buffers
			#pragma target 5.0

			struct Particle {
				float3 position;
				float3 velocity;
				float life;
			};

			struct v2g {
				float4 position : SV_POSITION;
				float4 color : COLOR;
				//float life : LIFE;
			};


			struct g2f {
				float4 pos : SV_POSITION;
				float3 norm : NORMAL;
				float2 uv : TEXCOORD0;
				float4 color: COLOR;
			};

			half _ParticleSize;
			sampler2D _MainTex;
			
			// particles' data
			StructuredBuffer<Particle> particleBuffer;


			v2g vert(uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID)
			{
				v2g o = (v2g)0;

				// Color
				float life = particleBuffer[instance_id].life;
				float lerpVal = life * 0.25f;
				o.color = fixed4(1.0f - lerpVal + 0.1, lerpVal + 0.1, 1.0f, lerpVal);

				// Position in worldspace
				o.position = float4(particleBuffer[instance_id].position, 1.0f);

				return o;
			}
			
			[maxvertexcount(4)]
			void geom(point v2g IN[1], inout TriangleStream<g2f> triStream) {

				g2f OUT;

				float pSize = 0.015;

				float3 v0 = IN[0].position - float4(0, pSize, 0,0);
				float3 v1 = IN[0].position + float4(0, pSize, 0,0);
				float3 quadOffset = float3(1, 0, 0) * pSize;
				// 1
				OUT.pos = UnityObjectToClipPos(v1 + quadOffset);
				OUT.norm = float3(1,0,0);
				OUT.uv = float2(1, 1);
				OUT.color = IN[0].color;
				triStream.Append(OUT);

				// 2
				OUT.pos = UnityObjectToClipPos(v0 + quadOffset);
				OUT.norm = float3(1, 0, 0);
				OUT.uv = float2(1, 0);
				triStream.Append(OUT);

				// 3
				OUT.pos = UnityObjectToClipPos(v1 - quadOffset);
				OUT.norm = float3(1,0, 0);;
				OUT.uv = float2(0, 1);
				triStream.Append(OUT);

				// 4
				OUT.pos = UnityObjectToClipPos(v0 - quadOffset);
				OUT.norm = float3(1,0, 0);;
				OUT.uv = float2(0, 0);
				triStream.Append(OUT);

				
			}
			
			float4 frag(g2f IN) : COLOR
			{
				float4 c = tex2D(_MainTex, IN.uv) * IN.color;
				clip(c.a - 0.1);

				return c;
			}

			ENDCG
		}
	}
	FallBack off
}