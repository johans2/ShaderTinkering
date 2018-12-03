// Water functions for position, normal and crest at given point
// Gerstner wave function: https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html

float _WaveLength1;
float _Amplitude1;
float _Speed1;
float _DirectionX1;
float _DirectionY1;
float _Steepness1;
float _FadeSpeed1;

float _FoamSpread;
float _FoamSharpness;

sampler2D _CameraDepthTexture;
sampler2D _WaterBackground;
float4 _CameraDepthTexture_TexelSize;
float4 _WaterFogColor;
float _WaterFogDensity;
float _RefractionStrength;

// Intersection foam
half _IntersectionFoamDensity;
sampler2D _IntersectionFoamRamp;
fixed4 _IntersectionFoamColor;

#if WAVE2
float _WaveLength2;
float _Amplitude2;
float _Speed2;
float _DirectionX2;
float _DirectionY2;
float _Steepness2;
float _FadeSpeed2;
#endif

#if WAVE3
float _WaveLength3;
float _Amplitude3;
float _Speed3;
float _DirectionX3;
float _DirectionY3;
float _Steepness3;
float _FadeSpeed3;
#endif

#if WAVE4
float _WaveLength4;
float _Amplitude4;
float _Speed4;
float _DirectionX4;
float _DirectionY4;
float _Steepness4;
float _FadeSpeed4;
#endif

#if WAVE5
float _WaveLength5;
float _Amplitude5;
float _Speed5;
float _DirectionX5;
float _DirectionY5;
float _Steepness5;
float _FadeSpeed5;
#endif

// Returns x,y,z position and w crestFactor (used for foam)
float4 WavePoint(float2 position, float amplitude, float wavelength, float speed, float2 direction, float steepness, float fadeSpeed) {
    half frequency = 2 / wavelength;
    half phaseConstantSpeed = speed * 2 / wavelength;
	

	half2 normalizedDir = normalize(direction);
    half fi = _Time.x  * phaseConstantSpeed;
    half dirDotPos = dot(normalizedDir, position);

	half fade = cos(fadeSpeed * _Time.x) / 2 + 0.5;
	amplitude *= fade;

    float waveGretsX = steepness * amplitude * normalizedDir.x * cos(frequency * dirDotPos + fi);
	float crest = sin(frequency * dirDotPos + fi);
    float waveGretsY = amplitude * crest;
    float waveGretsZ = steepness * amplitude * normalizedDir.y * cos(frequency * dirDotPos + fi);
	float crestFactor = crest * saturate(steepness) * fade;

    return float4(waveGretsX, waveGretsY, waveGretsZ, crestFactor);
}

float3 WaveNormal(float3 position, float amplitude, float wavelength, float speed, float2 direction, float steepness) {

	half frequency = 2 / wavelength;
	half phaseConstantSpeed = speed * 2 / wavelength;

	half2 normalizedDir = normalize(direction);
	half fi = _Time.x  * phaseConstantSpeed;
	half dirDotPos = dot(normalizedDir, position.xz);

	float WA = frequency * amplitude;
	float S = sin(frequency * dirDotPos + fi);
	float C = cos(frequency * dirDotPos + fi);

	float3 normal = float3 (
		normalizedDir.x * WA * C,
		min(0.2f,steepness * WA * S),
		normalizedDir.y * WA * C
	);

	return normal;
}

float4 WavePointSum(float3 worldPos) {
	float4 wavePointSum = WavePoint(worldPos.xz, 
									_Amplitude1, 
									_WaveLength1, 
									_Speed1, 
									float2(_DirectionX1, _DirectionY1), 
									_Steepness1,
									_FadeSpeed1);
	
	float totSteepness = _FoamSpread;

	#if WAVE2
	float4 wave2 = WavePoint(	worldPos.xz,
								_Amplitude2,
								_WaveLength2,
								_Speed2,
								float2(_DirectionX2, _DirectionY2),
								_Steepness2,
								_FadeSpeed2);
	
	wavePointSum += wave2;
	totSteepness += _FoamSpread;
	#endif


	#if WAVE3
	float4 wave3 = WavePoint	(worldPos.xz,
								_Amplitude3,
								_WaveLength3,
								_Speed3,
								float2(_DirectionX3, _DirectionY3),
								_Steepness3,
								_FadeSpeed3);

	wavePointSum += wave3;
	totSteepness += _FoamSpread;
	#endif


	#if WAVE4
	float4 wave4 = WavePoint(	worldPos.xz,
								_Amplitude4,
								_WaveLength4,
								_Speed4,
								float2(_DirectionX4, _DirectionY4),
								_Steepness4,
								_FadeSpeed4);

	wavePointSum += wave4;
	totSteepness += _FoamSpread;
	#endif


	#if WAVE5
	float4 wave5 = WavePoint(	worldPos.xz,
								_Amplitude5,
								_WaveLength5,
								_Speed5,
								float2(_DirectionX5, _DirectionY5),
								_Steepness5,
								_FadeSpeed5);

	wavePointSum += wave5;
	totSteepness += _FoamSpread;
	#endif

	wavePointSum.w /= totSteepness;
	wavePointSum.w = max(0.01, wavePointSum.w);
	return wavePointSum;
}

float3 WaveNormalSum(float3 wavePointSum) {
	float3 normalSum = WaveNormal(	wavePointSum,
									_Amplitude1, 
									_WaveLength1, 
									_Speed1, 
									float2(_DirectionX1, _DirectionY1),
									_Steepness1);

	#if WAVE2
		normalSum += WaveNormal(wavePointSum,
								_Amplitude2,
								_WaveLength2,
								_Speed2,
								float2(_DirectionX2, _DirectionY2),
								_Steepness2);
	#endif

	#if WAVE3
		normalSum += WaveNormal(wavePointSum,
								_Amplitude3,
								_WaveLength3,
								_Speed3,
								float2(_DirectionX3, _DirectionY3),
								_Steepness3);
	#endif
		
	#if WAVE4
		normalSum += WaveNormal(wavePointSum,
								_Amplitude4,
								_WaveLength4,
								_Speed4,
								float2(_DirectionX4, _DirectionY4),
								_Steepness4);
	#endif

	#if WAVE5
		normalSum += WaveNormal(wavePointSum,
								_Amplitude5,
								_WaveLength5,
								_Speed5,
								float2(_DirectionX5, _DirectionY5),
								_Steepness5);
	#endif

	return float3(-normalSum.x, 1 - normalSum.y, -normalSum.z);
}

float2 AlignWithGrabTexel(float2 uv) {
#if UNITY_UV_STARTS_AT_TOP
	if (_CameraDepthTexture_TexelSize.y < 0) {
		uv.y = 1 - uv.y;
	}
#endif

	return (floor(uv * _CameraDepthTexture_TexelSize.zw) + 0.5) * abs(_CameraDepthTexture_TexelSize.xy);
}

float3 ColorBelowWater(float4 screenPos, float3 tangentSpaceNormal) {
	float2 uvOffset = tangentSpaceNormal.xy * _RefractionStrength;
	uvOffset.y *= _CameraDepthTexture_TexelSize.z * abs(_CameraDepthTexture_TexelSize.y);
	float2 uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);

	float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
	float depthDifference = backgroundDepth - surfaceDepth;

	uvOffset *= saturate(depthDifference);
	uv = AlignWithGrabTexel((screenPos.xy + uvOffset) / screenPos.w);
	backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
	depthDifference = backgroundDepth - surfaceDepth;
    
    // Fog and refraction
	float3 backgroundColor = tex2D(_WaterBackground, uv).rgb;
	float fogFactor = saturate(exp2(-_WaterFogDensity * depthDifference));
	
	// Intersection foam
	float interSectionFoamRange = saturate(exp2(-_IntersectionFoamDensity * depthDifference)) ;
	float interSectionFoamFactor = tex2D(_IntersectionFoamRamp, float2(saturate(interSectionFoamRange), 0));
	
	// Final interpolated color
	float3 colorUnderWater = lerp(_WaterFogColor, backgroundColor, fogFactor); 
	float3 finalColor = lerp(_IntersectionFoamColor,colorUnderWater, 1 - interSectionFoamFactor);
	
	return finalColor;;
}
