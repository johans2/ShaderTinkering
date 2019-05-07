﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "BlackHole/Raymarching"
{
	Properties
	{
		_BlackHoleColor ("Black hole color", Color) = (0,0,0,1)
		_SchwarzschildRadius ("schwarzschildRadius", Float) = 0.5
		_SpaceDistortion ("Space distortion", Float) = 4.069
		_AccretionDiskColor("Accretion disk color", Color) = (1,1,1,1)
		_AccretionDiskThickness("Accretion disk thickness", Float) = 1
		_SkyCube("Skycube", Cube) = "defaulttexture" {}
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

			// Provided by our script
			uniform float4x4 _FrustumCornersES;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float3 _CameraWS;
			uniform float3 _LightDir;
			uniform sampler2D _Noise;
			float _SpaceDistortion;
			float _SchwarzschildRadius;
			half4 _AccretionDiskColor;
			half4 _BlackHoleColor;
			float _AccretionDiskThickness;
			samplerCUBE _SkyCube;


			// Input to vertex shader
			struct appdata
			{
				// Remember, the z value here contains the index of _FrustumCornersES to use
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			// Output of vertex shader / input to fragment shader
			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 ray : TEXCOORD1;
			};
			// Torus
			// t.x: diameter
			// t.y: thickness
			// Adapted from: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
			float sdTorus(float3 p, float2 t)
			{
				float2 q = float2(length(p.xz) - t.x, p.y);
				return length(q) - t.y;
			}

			float sdRoundedCylinder(float3 p, float ra, float rb, float h)
			{
				float2 d = float2(length(p.xz) - 2.0 * ra + rb, abs(p.y) - h);
				return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
			}

			// s: radius
			float sdSphere(float3 p, float s)
			{
				return length(p) - s;
			}

			float sdScaledTorus(float3 p, float2 t, float3 scale) {
				float3 q = p - clamp(p, -scale, scale);
				return sdTorus(q, t);
			}

			float opUnion(float d1, float d2) { 
				return min(d1, d2); 
			}

			float opSmoothUnion(float d1, float d2, float k) {
				float h = clamp(0.5 + 0.5*(d2 - d1) / k, 0.0, 1.0);
				return lerp(d2, d1, h) - k * h*(1.0 - h);
			}

			float opSmoothIntersection(float d1, float d2, float k) {
				float h = clamp(0.5 - 0.5*(d2 - d1) / k, 0.0, 1.0);
				return lerp(d2, d1, h) + k * h*(1.0 - h);
			}

			float opSmoothSubtraction(float d1, float d2, float k) {
				float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
				return lerp(d2, -d1, h) + k * h * (1.0 - h);
			}

			// This is the distance field function.  The distance field represents the closest distance to the surface
			// of any object we put in the scene.  If the given point (point p) is inside of an object, we return a
			// negative answer.
			float map(float3 p) {
				float p1 = sdRoundedCylinder(p, 3.5, 0.25, 0.01);
				float p2 = sdSphere(p, 3.5);
				return opSmoothSubtraction(p2, p1, 0.5);
			}

			float3 calcNormal(in float3 pos)
			{
				// epsilon - used to approximate dx when taking the derivative
				const float2 eps = float2(0.001, 0.0);

				// The idea here is to find the "gradient" of the distance field at pos
				// Remember, the distance field is not boolean - even if you are inside an object
				// the number is negative, so this calculation still works.
				// Essentially you are approximating the derivative of the distance field at this point.
				float3 nor = float3(
					map(pos + eps.xyy).x - map(pos - eps.xyy).x,
					map(pos + eps.yxy).x - map(pos - eps.yxy).x,
					map(pos + eps.yyx).x - map(pos - eps.yyx).x);
				return normalize(nor);
			}

			float GetSpaceDistortionLerpValue(float schwarzschildRadius, float distanceToSingularity, float spaceDistortion) {
				return pow(schwarzschildRadius, spaceDistortion) / pow(distanceToSingularity, spaceDistortion);
			}

			// Raymarch along given ray
			// ro: ray origin
			// rd: ray direction
			fixed4 raymarch(float3 ro, float3 rd) {
				fixed4 ret = _AccretionDiskColor;
				ret.a = 0;

				const int maxstep = 762;
				float3 previousPos = ro;
				float epsilon = 0.01;
				float stepSize = 0.05;
				float thickness = 0;

				float3 rayDir = rd;
				float3 blackHolePosition = float3(0, 0, 0);
				float distanceToSingularity = 99999999;
				float blackHoleInfluence = 0;
				half4 volumetricBaseColor = half4(0, 0, 0, 1);
				
				for (int i = 0; i < maxstep; ++i) {
					float3 unaffectedAddVector = normalize(rayDir) * stepSize;
					float3 maxAffectedAddVector = normalize(blackHolePosition - previousPos) * stepSize;
					distanceToSingularity = distance(blackHolePosition, previousPos);

					float lerpValue = GetSpaceDistortionLerpValue(_SchwarzschildRadius, distanceToSingularity, _SpaceDistortion);
					float3 addVector = normalize(lerp(unaffectedAddVector, maxAffectedAddVector, lerpValue)) * stepSize;

					float3 newPos = previousPos + addVector;
					
					float sdfResult = map(newPos);

					if (sdfResult < epsilon) {
						float u = cos(_Time.z * 1.5 - (distanceToSingularity * 1));
						float v = sin(_Time.z * 1.5 - (distanceToSingularity * 1));
						
						float2x2 rot = float2x2(u, -v, v, u);
						
						float2 uv = mul(rot, newPos.xz / 10);
						
						float noise = pow( tex2D(_Noise, uv).a, 1.5);

						thickness = noise * _AccretionDiskThickness;
						volumetricBaseColor += _AccretionDiskColor * thickness;
					}

					blackHoleInfluence = step(distanceToSingularity, _SchwarzschildRadius);
					previousPos = newPos;
					rayDir = addVector;
				}

				float3 skyColor = texCUBE(_SkyCube, rayDir).rgb;

				half4 backGround = lerp(float4(skyColor.rgb, 0), _BlackHoleColor, blackHoleInfluence);

				return backGround + volumetricBaseColor;
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

				fixed4 add = raymarch(ro, rd);

				return add;
			}
			ENDCG
		}
	}
}
