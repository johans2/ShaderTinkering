// Water functions for position, normal and crest at given point
// Gerstner wave function: https://developer.nvidia.com/gpugems/GPUGems/gpugems_ch01.html

float _WaveLength1;
float _Amplitude1;
float _Speed1;
float _DirectionX1;
float _DirectionY1;
float _Steepness1;
float _FadeSpeed1;

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
float4 WavePoint(float2 position, float amplitude, float wavelength, float speed, float2 direction, float steepness) {
    float frequency = 2 / wavelength;
    float phaseConstantSpeed = speed * 2 / wavelength;

	float2 normalizedDir = normalize(direction);
    float fi = _Time.x  * phaseConstantSpeed;
    float dirDotPos = dot(normalizedDir, position);

    float waveGretsX = steepness * amplitude * normalizedDir.x * cos(frequency * dirDotPos + fi);
	float crest = sin(frequency * dirDotPos + fi);
    float waveGretsY = amplitude * crest;
	//								-1 < x < 1
	//								max: amplitude * 1
    float waveGretsZ = steepness * amplitude * normalizedDir.y * cos(frequency * dirDotPos + fi);
	float crestFactor = (crest / amplitude) * saturate(steepness);

    return float4(waveGretsX, waveGretsY, waveGretsZ, crestFactor);
}

float3 WaveNormal(float3 position, float amplitude, float wavelength, float speed, float2 direction, float steepness) {

	float frequency = 2 / wavelength;
	float phaseConstantSpeed = speed * 2 / wavelength;

	float2 normalizedDir = normalize(direction);
	float fi = _Time.x  * phaseConstantSpeed;
	float dirDotPos = dot(normalizedDir, position.xz);

	float WA = frequency * amplitude;
	float S = sin(frequency * dirDotPos + fi);
	float C = cos(frequency * dirDotPos + fi);

	float3 normal = float3 (
		normalizedDir.x * WA * C,
		steepness * WA * S,
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
									_Steepness1);


	#if WAVE2
	float4 wave2 = WavePoint(	worldPos.xz,
								_Amplitude2,
								_WaveLength2,
								_Speed2,
								float2(_DirectionX2, _DirectionY2),
								_Steepness2);
	
	wavePointSum.xyz += wave2.xyz;
	wavePointSum.w += wave2.w;
	#endif


	#if WAVE3
	float4 wave3 = WavePoint	(worldPos.xz,
								_Amplitude3,
								_WaveLength3,
								_Speed3,
								float2(_DirectionX3, _DirectionY3),
								_Steepness3);
	wavePointSum.xyz += wave3.xyz;
	wavePointSum.w += wave3.w;
	#endif


	#if WAVE4
	float4 wave4 = WavePoint(	worldPos.xz,
								_Amplitude4,
								_WaveLength4,
								_Speed4,
								float2(_DirectionX4, _DirectionY4),
								_Steepness4);

	wavePointSum.xyz += wave4.xyz;
	wavePointSum.w += wave4.w;
	#endif


	#if WAVE5
	float4 wave5 = WavePoint(	worldPos.xz,
								_Amplitude5,
								_WaveLength5,
								_Speed5,
								float2(_DirectionX5, _DirectionY5),
								_Steepness5);

	wavePointSum.xyz += wave5.xyz;
	wavePointSum.w += wave5.w;
	#endif

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