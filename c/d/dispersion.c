#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_INPUT 128
#define OUTPUT_BYTES 16

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t dispersion(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length == 0 || length > MAX_INPUT) return -1;
    for (size_t i = 0; i < length; ++i) if (values[i] < -10000 || values[i] > 10000) return -1;
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;
    double sum = 0.0;
    for (size_t i = 0; i < length; ++i) sum += (double)values[i];
    double mean = sum / (double)length;
    double squared_deviations = 0.0;
    for (size_t i = 0; i < length; ++i) {
        double deviation = (double)values[i] - mean;
        squared_deviations += deviation * deviation;
    }
    double variance = squared_deviations / (double)length;
    double standard_deviation = sqrt(variance);
    put_f64_le(output, 0, variance);
    put_f64_le(output, 8, standard_deviation);
    return OUTPUT_BYTES;
}
