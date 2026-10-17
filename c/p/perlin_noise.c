#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 8
#define MAX_INPUT_ELEMENTS 5
#define MAX_PARSEABLE_INPUT_ELEMENTS 6
#define MAX_OUTPUT_ELEMENTS (MAX_DIMENSION * MAX_DIMENSION)
#define JAVA_MULTIPLIER UINT64_C(0x5DEECE66D)
#define JAVA_ADDEND UINT64_C(0xB)
#define JAVA_MASK ((UINT64_C(1) << 48) - 1)

static float rounded_add(float a, float b) { volatile float value = a + b; return value; }
static float rounded_sub(float a, float b) { volatile float value = a - b; return value; }
static float rounded_mul(float a, float b) { volatile float value = a * b; return value; }
static float rounded_div(float a, float b) { volatile float value = a / b; return value; }

static uint32_t java_next(uint64_t *state, unsigned bits) {
    *state = (*state * JAVA_MULTIPLIER + JAVA_ADDEND) & JAVA_MASK;
    return (uint32_t)(*state >> (48 - bits));
}

static float interpolate(float a, float b, float alpha) {
    const float one_minus_alpha = rounded_sub(1.0f, alpha);
    const float left = rounded_mul(a, one_minus_alpha);
    const float right = rounded_mul(alpha, b);
    return rounded_add(left, right);
}

static bool exact_integer(double value, double minimum, double maximum) {
    return value == value && value >= minimum && value <= maximum && (double)(int64_t)value == value;
}

int64_t perlin_noise(const double *input, size_t length, double *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > MAX_PARSEABLE_INPUT_ELEMENTS) return -1;
    if (length != MAX_INPUT_ELEMENTS) return -1;
    if (!exact_integer(input[0], 1.0, 8.0) || !exact_integer(input[1], 1.0, 8.0) ||
        !exact_integer(input[2], 1.0, 4.0) || !exact_integer(input[4], 0.0, 2147483647.0) ||
        (input[3] != 0.5 && input[3] != 0.75 && input[3] != 1.0)) return -1;

    const int width = (int)input[0], height = (int)input[1], octave_count = (int)input[2];
    const uint64_t seed = (uint64_t)input[4];
    const size_t count = (size_t)width * (size_t)height;
    float base[MAX_OUTPUT_ELEMENTS] = {0};
    float layers[4 * MAX_OUTPUT_ELEMENTS] = {0};
    float result[MAX_OUTPUT_ELEMENTS] = {0};

    uint64_t state = (seed ^ JAVA_MULTIPLIER) & JAVA_MASK;
    for (int x = 0; x < width; ++x) for (int y = 0; y < height; ++y) {
        base[x * height + y] = rounded_div((float)java_next(&state, 24), 16777216.0f);
    }

    for (int octave = 0; octave < octave_count; ++octave) {
        const int period = 1 << octave;
        const float frequency = rounded_div(1.0f, (float)period);
        float *layer = layers + (size_t)octave * MAX_OUTPUT_ELEMENTS;
        for (int x = 0; x < width; ++x) {
            const int x0 = (x / period) * period;
            const int x1 = (x0 + period) % width;
            const float horizontal = rounded_mul((float)(x - x0), frequency);
            for (int y = 0; y < height; ++y) {
                const int y0 = (y / period) * period;
                const int y1 = (y0 + period) % height;
                const float vertical = rounded_mul((float)(y - y0), frequency);
                const float top = interpolate(base[x0 * height + y0], base[x1 * height + y0], horizontal);
                const float bottom = interpolate(base[x0 * height + y1], base[x1 * height + y1], horizontal);
                layer[x * height + y] = interpolate(top, bottom, vertical);
            }
        }
    }

    float amplitude = 1.0f, total_amplitude = 0.0f;
    const float persistence = (float)input[3];
    for (int octave = octave_count - 1; octave >= 0; --octave) {
        amplitude = rounded_mul(amplitude, persistence);
        total_amplitude = rounded_add(total_amplitude, amplitude);
        const float *layer = layers + (size_t)octave * MAX_OUTPUT_ELEMENTS;
        for (size_t i = 0; i < count; ++i) result[i] = rounded_add(result[i], rounded_mul(layer[i], amplitude));
    }
    const float inverse_total = rounded_div(1.0f, total_amplitude);
    for (size_t i = 0; i < count; ++i) result[i] = rounded_mul(result[i], inverse_total);

    if (output == NULL || output_capacity < count) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = (double)result[i];
    return (int64_t)count;
}
