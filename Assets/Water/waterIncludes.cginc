// Water functions for position and normal at given point


float _WaveLength1;
float _Amplitude1;
float _Speed1;
float _DirectionX1;
float _DirectionY1;
float _Steepness1;
float _FadeSpeed1;

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