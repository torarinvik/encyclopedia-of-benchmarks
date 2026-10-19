#include <stddef.h>
#include <stdint.h>

enum { CHANNELS = 12, INPUT_LENGTH = 48 };
static float add32(float a, float b) { volatile float r = a + b; return r; }
static float sub32(float a, float b) { volatile float r = a - b; return r; }
static float mul32(float a, float b) { volatile float r = a * b; return r; }

int64_t versabench_beamformer(const double *input, size_t length,
                              double *output, size_t capacity) {
    if (input == NULL || length != INPUT_LENGTH) return -1;
    float v[INPUT_LENGTH];
    for (size_t i = 0; i < INPUT_LENGTH; ++i) {
        if (input[i] != input[i] || input[i] < -128.0 || input[i] > 128.0) return -1;
        v[i] = (float)input[i];
    }
    float real = 0.0f, imag = 0.0f;
    for (size_t channel = 0; channel < CHANNELS; ++channel) {
        const size_t b = 4 * channel;
        const float rr = sub32(mul32(v[b], v[b + 2]), mul32(v[b + 1], v[b + 3]));
        const float ii = add32(mul32(v[b], v[b + 3]), mul32(v[b + 1], v[b + 2]));
        real = add32(real, rr);
        imag = add32(imag, ii);
    }
    if (output == NULL || capacity < 2) return -2;
    output[0] = (double)real;
    output[1] = (double)imag;
    return 2;
}
