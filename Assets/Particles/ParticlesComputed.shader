Shader "Custom/ParticlesComputed" {
	Properties {
		_ParticleSize("ParticleSize", Float) = 0.01
	}

	SubShader {
		Pass {
			Tags { "RenderType" = "Opaque" }
			LOD 200
			Blend SrcAlpha one

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

			// particles' data
			StructuredBuffer<Particle> particleBuffer;


			v2g vert(uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID)
			{
				v2g o = (v2g)0;

				// Color
				float life = particleBuffer[instance_id].life;
				float lerpVal = life * 0.25f;
				o.color = fixed4(1.0f - lerpVal + 0.1, lerpVal + 0.1, 1.0f, lerpVal);

				// Position
				o.position = UnityObjectToClipPos(float4(particleBuffer[instance_id].position, 1.0f));

				return o;
			}
			
			[maxvertexcount(1)]
			void geom(point v2g IN[1], inout PointStream<g2f> triStream) {

				g2f OUT;
				OUT.pos = IN[0].position;
				OUT.norm = float3(1, 1, 1);
				OUT.uv = float2(0.5, 0.5);
				OUT.color = IN[0].color;

				triStream.Append(OUT);

			}
			
			float4 frag(g2f i) : COLOR
			{
				return i.color;
			}

			ENDCG
		}
	}
	FallBack off
}