Shader "Custom/SvenssonToonLighting"
{
	Properties
	{
		[Header(Diffuse)]
		_MainTex ("Main Texture", 2D) = "white" {}
		_Color ("Albedo", color) = (1., 1., 1., 1.)
		_ToonRamp("Toon ramp", 2D) = "white" {}
		_ShadowColor ("Shadow color", color) = (1., 1., 1., 1.)

		[Header(Specular)]
		[Toggle(ENABLE_SPEC)] _SpecEnabled ("Enabled", Float) = 0
		_Shininess ("Shininess", Range(0.1, 10)) = 1.
		_SpecIntensity ("Specular intensity", Range(0.0, 2)) = 0.1
		_SpecColor ("Specular color", color) = (1., 1., 1., 1.)
		_SpecRamp("Specular ramp", 2D) = "white" {}

		[Header(Rim light)]
		[Toggle(ENABLE_RIM)] _RimEnabled ("Enabled", Float) = 0
		_RimColor ("Rim color", color) = (1., 1., 1., 1.)
		_RimPower ("Rim power", Range(0.1, 10)) = 3.

		[Header(Recieve shadows)]
		[Toggle(ENABLE_ADVANCED_SHADOWS)] _AdvancedShadowsEnabled ("Enabled", Float) = 0
		_ShadowRamp("Shadow ramp", 2D) = "white" {}

    }
 
	SubShader
	{
		Cull back

		Pass
		{
			Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" "Pass" = "OnlyDirectional"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag 
			#pragma multi_compile_fwdbase
			#pragma shader_feature ENABLE_SPEC
			#pragma shader_feature ENABLE_RIM
			#pragma shader_feature ENABLE_ADVANCED_SHADOWS
			#pragma shader_feature ENABLE_CUTOUT_ALPHA
 
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
 
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : NORMAL;

				#if ENABLE_ADVANCED_SHADOWS
				LIGHTING_COORDS(2, 3)
				#endif
			};
 
			v2f vert(appdata_base v)
			{
				v2f o;
				// World position
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
 
				// Clip position
				o.pos = mul(UNITY_MATRIX_VP, float4(o.worldPos, 1.));
 
				// Normal in WorldSpace
				o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
 
				o.uv = v.texcoord;

				#if ENABLE_ADVANCED_SHADOWS
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				#endif

				return o;
			}
 			
			// Diffuse
			sampler2D _MainTex;
			sampler2D _ToonRamp;
			fixed4 _LightColor0;
			fixed4 _Color;
			fixed4 _ShadowColor;
           	
			//Specular
			fixed _Shininess;
			fixed _SpecIntensity;
			fixed4 _SpecColor;
			sampler2D _SpecRamp;

			// Rim
			fixed4 _RimColor;
			float _RimPower;

			// Advanced shadows
			sampler2D _ShadowRamp;
 
			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 c = tex2D(_MainTex, i.uv);
 				
				float3 light = {0.0,0.0,0.0};

				// Light direction
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                
				// Camera direction
				half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

				// -------------------- DIFFUSE LIGHT ----------------------

				// This will be light added to all parts of the obejct, including dark ones.
				half3 indirectDiffuse = unity_AmbientSky;

				// Compute the diffuse lighting
				half NdotL = max(0., dot(i.worldNormal, lightDir));

				// Sample the lut texture, float2(<the light value [0...1]>, 0). Creating the cell shading.                
				half toonRamp = tex2D(_ToonRamp, float2(NdotL, 0));

				// Diffuse based on light source
				half3 directDiffuse = toonRamp * _LightColor0;

				// Light = direct + indirect;
				half3 diffuse = indirectDiffuse + directDiffuse;

				// Add shadow color.
				diffuse += (_ShadowColor * (1.0 - toonRamp));

				// -------------------- SPECULAR LIGHT ----------------------
                
				#if ENABLE_SPEC

				// Get the light reflection across the normal.
				half3 refl = normalize(reflect(-lightDir, i.worldNormal));

				// Calculate dot product between the reflection diretion and the view direction [0...1]
				half RdotV = max(0., dot(refl, viewDir));

				// Make large values really large and small values really small.
				half specPow = pow(RdotV, _Shininess);

				// Sample the ramp texture for a smooth falloff.
				half3 specRamp = tex2D(_SpecRamp , float2(specPow, 0));

				// Multiply by NdotL to make non lit areas not  get spec (kinda works).
				half3 spec = specRamp * toonRamp * _LightColor0 * _SpecColor * pow(_SpecIntensity,2);

				#endif

				// ----------------------- RIM LIGHT ------------------------

				#if ENABLE_RIM
				// Light based only on view direction and normal
				half rimAmount = 1 - saturate(dot(normalize(viewDir), i.worldNormal));
				half3 rim = _RimColor * pow(rimAmount, _RimPower);
				#endif


				// ------------------- RECIEVE SHADOWS ---------------------

				#if ENABLE_ADVANCED_SHADOWS
				// Get the light attenuation
				half attenuation = LIGHT_ATTENUATION(i);

				// Get the ramped shadow from the _ShadowRamp texture based on attenuation
				half shadowRamp = tex2D(_ShadowRamp , float2(attenuation, 0)).r;

				// Modify existing light based on the ramped shadow
				diffuse = indirectDiffuse + (directDiffuse * shadowRamp);
				
				// Add Shadow color
				diffuse += (_ShadowColor * (1.0 - min(shadowRamp, toonRamp)));

				#if ENABLE_SPEC
				spec *= shadowRamp;
				#endif

				#endif

				// --------------------- FINAL LIGHT ------------------------

				light += diffuse;

				#if ENABLE_RIM
				light += rim;
				#endif

				#if ENABLE_SPEC
				light += spec;
				#endif

				c.rbg *= _Color;
				c.rgb *= light.rgb;

				// ------------------- ALPHA CLIPPING ----------------------

				clip(c.a - 0.1);

				return c;
			}
 
			ENDCG
		}
	}
    // This fallback makes the shader cast shadows
	Fallback "Transparent/Cutout/Diffuse"
}
