Shader "Custom/FireParticlesComputed" {
	Properties{
		_ParticleSize("ParticleSize", Float) = 0.01
		_MainTex("Particle texture", 2D) = "white" {}
		_ColorRampTex("Color ramp texture", 2D) = "white" {}
		_TotalSmokeDistance("Particle total smoke distance", Float) = 5.0
		_SizeByLifeMin("Size by life min",  Float) = 0.015
		_SizeByLifeMax("Size by life min",  Float) = 0.03
	}

	SubShader {
		Pass {
			Tags{ "Queue" = "Opaque" "RenderType" = "Opaque" }
			LOD 200
			Cull front
			ZWrite off

			Blend SrcAlpha OneMinusSrcAlpha

			//BlendOp Add


			//Blend SrcAlpha One
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"

					// Use shader model 5.0 target, to be able to use buffers
			#pragma target 5.0

			struct Particle
			{
				float3 startPos;
				float3 position;
				float3 velocity;
				float3 convergenceTarget;
				float life;
				float colorLookup;
				float STRIDE_FILLER1;
				float STRIDE_FILLER2;
			};

			struct v2g {
				float4 position : SV_POSITION;
				float4 color : COLOR;
				float distance : DISTANCE;
			};


			struct g2f {
				float4 pos : SV_POSITION;
				float3 norm : NORMAL;
				float2 uv : TEXCOORD0;
				float4 color: COLOR;
			};

			half _ParticleSize;
			half _TotalSmokeDistance;
			half _SizeByLifeMin;
			half _SizeByLifeMax;
			sampler2D _MainTex;
			sampler2D _ColorRampTex;

			// particles' data
			StructuredBuffer<Particle> particleBuffer;


			v2g vert(uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID)
			{
				v2g output = (v2g)0;

				// Need to calculate the distance from the start position in order to alter the size from that value in the geom function.
				float3 pos = particleBuffer[instance_id].position;
				float3 startPos = particleBuffer[instance_id].startPos;
				float distance = length(pos - startPos);

				// Color
				float4 color = tex2Dlod(_ColorRampTex, float4(particleBuffer[instance_id].colorLookup - 0.001, 0, 0, 0));
				color.a = 1.1 - particleBuffer[instance_id].colorLookup;

				output.color = color;
				output.distance = distance;
				// Position in worldspace
				output.position = float4(particleBuffer[instance_id].position, 1.0f);

				return output;
			}

			[maxvertexcount(3)]
			void geom(point v2g IN[1], inout TriangleStream<g2f> triStream) {

				g2f OUT;

				float pSize = lerp(_SizeByLifeMin, _SizeByLifeMax, saturate(IN[0].distance / _TotalSmokeDistance));//0.015;
				
				float3 v0 = IN[0].position - float4(0, pSize, 0,0);
				float3 v1 = IN[0].position + float4(0, pSize, 0,0);
		
				float3 camToPos = IN[0].position - _WorldSpaceCameraPos;
		
				float3 perpVector = normalize(cross(camToPos, float3(0, 1, 0))) * pSize;



				// 1
				OUT.pos = UnityObjectToClipPos(v1);
				OUT.norm = float3(1,0,0);
				OUT.uv = float2(0.5,1);
				OUT.color = IN[0].color;
				triStream.Append(OUT);

				// 2
				OUT.pos = UnityObjectToClipPos(v0 + perpVector);
				OUT.norm = float3(1, 0, 0);
				OUT.uv = float2(0, 0);
				triStream.Append(OUT);

				// 3
				OUT.pos = UnityObjectToClipPos(v0 - perpVector);
				OUT.norm = float3(1,0, 0);;
				OUT.uv = float2(1, 0);
				triStream.Append(OUT);

			}

			float4 frag(g2f IN) : COLOR
			{
				float4 c = tex2D(_MainTex, IN.uv) * IN.color;
				//clip(c.a - 0.1);

				return c;
			}

			ENDCG
		}
	}
	FallBack off
}