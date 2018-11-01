// Water functions for position and normal at given point

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

float3 WavePoint(float2 position, float amplitude, float wavelength, float speed, float2 direction, float steepness) {
    float frequency = 2 / wavelength;
    float phaseConstantSpeed = speed * 2 / wavelength;

    float fi = _Time.x  * phaseConstantSpeed;
    float dirDotPos = dot(direction, position);

    float waveGretsX = steepness * amplitude * direction.x * cos(frequency * dirDotPos + fi);
    float waveGretsY = amplitude * sin(frequency * dirDotPos + fi);
    float waveGretsZ = steepness * amplitude * direction.y * cos(frequency * dirDotPos + fi);

    return float3(waveGretsX, waveGretsY, waveGretsZ);
}

float3 WaveNormal(float3 position, float amplitude, float wavelength, float speed, float2 direction, float steepness) {

	float frequency = 2 / wavelength;
	float phaseConstantSpeed = speed * 2 / wavelength;

	float fi = _Time.x  * phaseConstantSpeed;
	float dirDotPos = dot(direction, position.xz);

	float WA = frequency * amplitude;
	float S = sin(frequency * dirDotPos + fi);
	float C = cos(frequency * dirDotPos + fi);

	float3 normal = float3 (
		direction.x * WA * C,
		steepness * WA * S,
		direction.y * WA * C
	);

	return normal;
}