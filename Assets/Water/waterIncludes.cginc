// Water functions for position and normal at given point

float3 WavePoint(float2 position, float amplitude, float wavelength, float speed, float2 direction, float steepness) {
    float frequency = 2 / wavelength;
    float phaseConstantSpeed = speed * (2 / wavelength);

    float fi = _Time.x  * phaseConstantSpeed;
    float dirDotPos = dot(direction, position);

    float waveGretsX = position.x + steepness * amplitude * direction.x * cos(frequency * dirDotPos + fi);
    float waveGretsY = position.y + steepness * amplitude * direction.y * cos(frequency * dirDotPos + fi);
    float waveGretsZ = amplitude * sin(frequency * dirDotPos + fi);

    return float3(waveGretsX, waveGretsY, waveGretsZ);
}