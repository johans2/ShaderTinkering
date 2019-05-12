// Created by Johan Svensson. https://medium.com/dotcrossdot
// Raymarching setup based on http://flafla2.github.io/2016/10/01/raymarching.html.
// The raymarching algorithm is changed to have a fixed step distance for volumetric sampling
// and create a light bending black hole with an accretion disk around it. 

Shader "DotCrossDot/BlackHoleRaymarching"
{
	Properties
	{
		_BlackHoleColor ("Black hole color", Color) = (0,0,0,1)
		_SchwarzschildRadius ("schwarzschildRadius", Float) = 0.5
		_SpaceDistortion ("Space distortion", Float) = 4.069
		_AccretionDiskColor("Accretion disk color", Color) = (1,1,1,1)
		_AccretionDiskThickness("Accretion disk thickness", Float) = 1
		_SkyCube("Skycube", Cube) = "defaulttexture" {}
		_Noise("Accretion disk noise", 2D) = "" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			// Set from script.
			uniform float4x4 _FrustumCornersES;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float3 _CameraWS;

			// Set from material.
			uniform sampler2D _Noise;
			float _SpaceDistortion;
			float _SchwarzschildRadius;
			half4 _AccretionDiskColor;
			half4 _BlackHoleColor;
			float _AccretionDiskThickness;
			samplerCUBE _SkyCube;

			struct appdata
			{
				// The z value here contains the index of _FrustumCornersES to use
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 ray : TEXCOORD1;
			};
			
			float sdSphere(float3 p, float s)
			{
				return length(p) - s;
			}

			float sdRoundedCylinder(float3 p, float ra, float rb, float h)
			{
				float2 d = float2(length(p.xz) - 2.0 * ra + rb, abs(p.y) - h);
				return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
			}

			float opSmoothSubtraction(float d1, float d2, float k) {
				float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
				return lerp(d2, -d1, h) + k * h * (1.0 - h);
			}

			// A SDF combination creating something that looks like an accretion disk.
			// Made up of a flattened rounded cylinder from which we subtract a sphere.
			float accretionDiskSDF(float3 p) {
				float p1 = sdRoundedCylinder(p, 3.5, 0.25, 0.01);
				float p2 = sdSphere(p, 3.5);
				return opSmoothSubtraction(p2, p1, 0.5);
			}

			// An (very rough!!) approximation of how light is bent given the distance to a black hole. 
			float GetSpaceDistortionLerpValue(float schwarzschildRadius, float distanceToSingularity, float spaceDistortion) {
				return pow(schwarzschildRadius, spaceDistortion) / pow(distanceToSingularity, spaceDistortion);
			}

			fixed4 raymarch(float3 ro, float3 rd) {
				fixed4 ret = _AccretionDiskColor;
				ret.a = 0;

				const int maxstep = 762;
				float3 previousPos = ro;
				float epsilon = 0.01;
				float stepSize = 0.05;
				float thickness = 0;

				float3 previousRayDir = rd;
				float3 blackHolePosition = float3(0, 0, 0);
				float distanceToSingularity = 99999999;
				float blackHoleInfluence = 0;
				half4 lightAccumulation = half4(0, 0, 0, 1);
				half rotationSpeed = 1.5;
				half noiseScale = 0.1;
				
				for (int i = 0; i < maxstep; ++i) {
					// Get two vectors. One pointing in previous direction and one pointing to the singularity. 
					float3 unaffectedDir = normalize(previousRayDir) * stepSize;
					float3 maxAffectedDir = normalize(blackHolePosition - previousPos) * stepSize;
					distanceToSingularity = distance(blackHolePosition, previousPos);

					// Calculate how to interpolate between the two previously calculated vectors.
					float lerpValue = GetSpaceDistortionLerpValue(_SchwarzschildRadius, distanceToSingularity, _SpaceDistortion);
					float3 newRayDir = normalize(lerp(unaffectedDir, maxAffectedDir, lerpValue)) * stepSize;

					// Move the lightray along and calculate the sdf result
					float3 newPos = previousPos + newRayDir;
					float sdfResult = accretionDiskSDF(newPos);

					// Inside the acceration disk. Sample light.
					if (sdfResult < epsilon) {
						// Rotate the texture sampling to fake motion.
						float u = cos(_Time.z * rotationSpeed - (distanceToSingularity));
						float v = sin(_Time.z * rotationSpeed - (distanceToSingularity));
						float2x2 rot = float2x2(u, -v, v, u);
						float2 uv = mul(rot, newPos.xz * noiseScale);

						// Get thickness from the noise texture.
						float noise = pow( tex2D(_Noise, uv).a, 1.5);
						thickness = noise * _AccretionDiskThickness;

						// Add to the rays light accumulation.
						lightAccumulation += _AccretionDiskColor * thickness;
					}

					// Calculate black hole influence on the final color.
					blackHoleInfluence = step(distanceToSingularity, _SchwarzschildRadius);
					previousPos = newPos;
					previousRayDir = newRayDir;
				}

				// Sample the skybox.
				float3 skyColor = texCUBE(_SkyCube, previousRayDir).rgb;

				// Sample let background be either skybox or the black hole color.
				half4 backGround = lerp(float4(skyColor.rgb, 0), _BlackHoleColor, blackHoleInfluence);

				// Return background and light.
				return backGround + lightAccumulation;
			}

			v2f vert(appdata v)
			{
				v2f o;

				// Index passed via custom blit function in RaymarchGeneric.cs
				half index = v.vertex.z;
				v.vertex.z = 0.1;

				o.pos = UnityObjectToClipPos(v.vertex);
				
				// Get the eyespace view ray (normalized)
				o.ray = _FrustumCornersES[(int)index].xyz;

				// Transform the ray from eyespace to worldspace
				// Note: _CameraInvViewMatrix was provided by the script
				o.ray = mul(_CameraInvViewMatrix, o.ray);
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				// ray direction
				float3 rd = normalize(i.ray.xyz);
				// ray origin (camera position)
				float3 ro = _CameraWS;

				fixed4 col = raymarch(ro, rd);

				return col;
			}
			ENDCG
		}
	}
}
