#include <stddef.h>
#include <stdint.h>

#define MAX_BINS 256
#define MAX_SAMPLES 1024
#define MAX_INPUT (3 + MAX_SAMPLES)

int64_t parboil_histo(const int64_t *input, size_t length,
                      uint8_t *output, size_t capacity) {
    uint8_t histogram[MAX_BINS] = {0};
    int64_t iterations, bins, samples;
    size_t i;
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    iterations = input[0]; bins = input[1]; samples = input[2];
    if (iterations < 0 || iterations > 8 || bins < 1 || bins > MAX_BINS ||
        samples < 0 || samples > MAX_SAMPLES || length != (size_t)(3 + samples)) return -1;
    for (i = 0; i < (size_t)samples; ++i)
        if (input[3 + i] < 0 || input[3 + i] >= bins) return -1;
    if (output == NULL || capacity < (size_t)bins) return -2;
    for (int64_t iter = 0; iter < iterations; ++iter) {
        for (i = 0; i < (size_t)bins; ++i) histogram[i] = 0;
        for (i = 0; i < (size_t)samples; ++i) {
            uint8_t value = histogram[(size_t)input[3 + i]];
            if (value < 255u) histogram[(size_t)input[3 + i]] = (uint8_t)(value + 1);
        }
    }
    for (i = 0; i < (size_t)bins; ++i) output[i] = histogram[i];
    return bins;
}
