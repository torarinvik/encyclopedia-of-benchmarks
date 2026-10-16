#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define OUTPUT_LENGTH 4

static int64_t round_ties_to_even(double value) {
    const double lower = floor(value);
    const double fraction = value - lower;
    const int64_t base = (int64_t)lower;
    if (fraction < 0.5) return base;
    if (fraction > 0.5) return base + 1;
    return (base & 1) == 0 ? base : base + 1;
}

int64_t rgb_cmyk_conversion(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3) return -1;
    for (size_t i = 0; i < 3; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == NULL || capacity < OUTPUT_LENGTH) return -2;
    const double red = (double)input[0] / 255.0;
    const double green = (double)input[1] / 255.0;
    const double blue = (double)input[2] / 255.0;
    double maximum = red;
    if (green > maximum) maximum = green;
    if (blue > maximum) maximum = blue;
    const double key = 1.0 - maximum;
    if (key == 1.0) {
        output[0] = output[1] = output[2] = 0;
        output[3] = 100;
        return OUTPUT_LENGTH;
    }
    const double denominator = 1.0 - key;
    output[0] = (uint8_t)round_ties_to_even(100.0 * (1.0 - red - key) / denominator);
    output[1] = (uint8_t)round_ties_to_even(100.0 * (1.0 - green - key) / denominator);
    output[2] = (uint8_t)round_ties_to_even(100.0 * (1.0 - blue - key) / denominator);
    output[3] = (uint8_t)round_ties_to_even(100.0 * key);
    return OUTPUT_LENGTH;
}
