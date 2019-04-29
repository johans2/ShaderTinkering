// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/Raymarching"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float3 _CameraWS;
			uniform float3 _LightDir;

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
				float2 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};
			/*
			float opElongate(in sdf3d primitive, in vec3 p, in vec3 h)
			{
				vec3 q = p - clamp(p, -h, h);
				return primitive(q);
			}*/

			// Torus
			// t.x: diameter
			// t.y: thickness
			// Adapted from: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
			float sdTorus(float3 p, float2 t)
			{
				float2 q = float2(length(p.xz) - t.x, p.y);
				return length(q) - t.y;
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

			// This is the distance field function.  The distance field represents the closest distance to the surface
			// of any object we put in the scene.  If the given point (point p) is inside of an object, we return a
			// negative answer.
			float map(float3 p) {
				return opSmoothUnion(  sdTorus(p, float2(2, 0.4)), sdSphere(p, 1.7), 0.3);
				//return sdTorus(p, float2(3, 0.5));
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

			// Raymarch along given ray
			// ro: ray origin
			// rd: ray direction
			fixed4 raymarch(float3 ro, float3 rd) {
				fixed4 ret = fixed4(0, 0, 0, 0);

				const int maxstep = 2256;
				float t = 0; // current distance traveled along ray
				float3 previousPos = ro;
				bool doInside = false;
				float epsilon = 0.0001;
				float stepSize = 0.01;
				float thickness = 0;

				for (int i = 0; i < maxstep; ++i) {
					float3 newPos = previousPos + rd * stepSize; // World space position of sample
					float sdfResult = map(newPos);       // Sample of distance field (see map())

					// If the sample <= 0, we have hit something (see map()).
					if (sdfResult < epsilon) {
						thickness += stepSize;
					}

					// If the sample > 0, we haven't hit anything yet so we should march forward
					// We step forward by distance d, because d is the minimum distance possible to intersect
					// an object (see map()).
					previousPos = newPos;

				}
				ret.a = thickness;


				/*
				// March to outside
				for (int i = 0; i < maxstep; ++i) {
					float3 newPos = previousPos + rd * t; // World space position of sample
					float sdfResult = map(newPos);       // Sample of distance field (see map())

					// If the sample <= 0, we have hit something (see map()).
					if (sdfResult < epsilon) {
						// Lambertian Lighting
						float3 n = calcNormal(newPos);
						ret = fixed4(dot(-_LightDir.xyz, n).rrr, 1);
						doInside = true;
						previousPos = newPos;
						break;
					}

					// If the sample > 0, we haven't hit anything yet so we should march forward
					// We step forward by distance d, because d is the minimum distance possible to intersect
					// an object (see map()).
					previousPos = newPos;
					t = sdfResult;
				}
				*/
				/*
				// March on inside
				if (doInside)
				{
					previousPos += rd * epsilon * 6;
					float insideDistance = 0;
					
					for (int i = 0; i < maxstep; ++i) {
						float3 newPos = previousPos + rd * abs(insideDistance); // World space position of sample
						float sdfResult = map(newPos);       // Sample of distance field (see map())
						insideDistance += sdfResult;
						// If the sample <= 0, we have hit something (see map()).
						if (sdfResult > 0) {
							break;
						}

						// If the sample > 0, we haven't hit anything yet so we should march forward
						// We step forward by distance d, because d is the minimum distance possible to intersect
						// an object (see map()).
					}
					
					ret.a *= (abs(insideDistance) -0.2);
					ret.a = clamp(ret.a, 0, 1);
				}*/
				
				return ret;
			}

			v2f vert(appdata v)
			{
				v2f o;

				// Index passed via custom blit function in RaymarchGeneric.cs
				half index = v.vertex.z;
				v.vertex.z = 0.1;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;

#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					o.uv.y = 1 - o.uv.y;
#endif

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

				fixed3 col = tex2D(_MainTex,i.uv); // Color of the scene before this shader was run
				fixed4 add = raymarch(ro, rd);

				// Returns final color using alpha blending
				return fixed4(col*(1.0 - add.w) + add.xyz * add.w,1.0);
			}
			ENDCG
		}
	}
}
