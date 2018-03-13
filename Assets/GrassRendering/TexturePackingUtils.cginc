// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

uint RGBAtoUINT(float4 color)
{
    //uint4 bitShifts = uint4(24, 16, 8, 0);
    //uint4 colorAsBytes = uint4(color * 255.0f) << bitShifts;

    uint4 kEncodeMul = uint4(16777216, 65536, 256, 1);
    uint4 colorAsBytes = round(color * 255.0f);

    return dot(colorAsBytes, kEncodeMul);
}

float4 UINTtoRGBA(uint value)
{
    uint4 bitMask = uint4(0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
    uint4 bitShifts = uint4(24, 16, 8, 0);

    uint4 color = (uint4)value & bitMask;
    color >>= bitShifts;

    return color / 255.0f;
}

inline float PackFloat(float value)
{
    return (value + 1.0) / 2;
}

inline float UnPackFloat(float value)
{
    return (value * 2) - 1;
}