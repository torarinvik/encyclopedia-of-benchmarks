#include <stddef.h>
#include <stdint.h>
#include <float.h>
#include <string.h>

static void put_f32_le(uint8_t *output, size_t offset, float value) {
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t julia_sets(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > 68) return -1;
    const int64_t iterations = input[0], cr_units = input[1], ci_units = input[2], count_value = input[3];
    if (iterations < 0 || iterations > 8 || count_value < 0 || count_value > 32 ||
        cr_units < -128 || cr_units > 128 || ci_units < -128 || ci_units > 128) return -1;
    const size_t count = (size_t)count_value;
    if (length != 4 + 2 * count) return -1;
    for (size_t i = 0; i < 2 * count; ++i)
        if (input[4 + i] < -128 || input[4 + i] > 128) return -1;
    const size_t needed = 8 * count;
    if (output == NULL || capacity < needed) return -2;

    const float cr = (float)cr_units / 16.0f, ci = (float)ci_units / 16.0f;
    float computed[64];
    for (size_t point = 0; point < count; ++point) {
        float real = (float)input[4 + 2 * point] / 16.0f;
        float imag = (float)input[5 + 2 * point] / 16.0f;
        for (int64_t step = 0; step < iterations; ++step) {
            const float real_square = real * real;
            const float imag_square = imag * imag;
            const float real_imag = real * imag;
            const float imag_real = imag * real;
            const float next_real = (real_square - imag_square) + cr;
            const float next_imag = (real_imag + imag_real) + ci;
            if (!(next_real <= FLT_MAX && next_real >= -FLT_MAX) ||
                !(next_imag <= FLT_MAX && next_imag >= -FLT_MAX)) return -1;
            real = next_real;
            imag = next_imag;
        }
        computed[2 * point] = real;
        computed[2 * point + 1] = imag;
    }
    for (size_t component = 0; component < 2 * count; ++component)
        put_f32_le(output, component * 4, computed[component]);
    return (int64_t)needed;
}
