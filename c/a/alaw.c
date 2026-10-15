#include <stdint.h>

int64_t alaw_encode(int64_t input)
{
    if (input < -32768 || input > 32767) return -1;

    const int32_t sample = (int32_t)input;
    const int32_t sign = sample < 0 ? 0x80 : 0;
    const int32_t magnitude = sample < 0 ? -sample - 1 : sample;
    int32_t segment = 7;
    int32_t mask = 0x4000;
    while ((magnitude & mask) == 0 && segment > 0) {
        --segment;
        mask >>= 1;
    }
    const int32_t shift = segment != 0 ? segment + 3 : 4;
    const int32_t quantization = (magnitude >> shift) & 0x0f;
    return (sign | (segment << 4) | quantization) ^ 0xD5;
}
