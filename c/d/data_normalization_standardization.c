#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_SAMPLE_COUNT 128
#define MAX_VALUE 100000
#define MIN_VALUE (-100000)

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t data_normalization_standardization(const int64_t *values, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (values == NULL || length < 4 || length > MAX_SAMPLE_COUNT + 2) return -1;
    const int64_t mode = values[0];
    const int64_t count_arg = values[1];
    if ((mode != 0 && mode != 1) || count_arg < 2 || count_arg > MAX_SAMPLE_COUNT ||
        length != (size_t)count_arg + 2) return -1;

    const size_t count = (size_t)count_arg;
    int64_t minimum = values[2];
    int64_t maximum = values[2];
    double sum = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = values[index + 2];
        if (value < MIN_VALUE || value > MAX_VALUE) return -1;
        if (value < minimum) minimum = value;
        if (value > maximum) maximum = value;
        sum += (double)value;
    }
    if (minimum == maximum) return -1;
    const size_t output_bytes = count * 8;
    if (output == NULL || capacity < output_bytes) return -2;

    if (mode == 0) {
        const double span = (double)(maximum - minimum);
        for (size_t index = 0; index < count; ++index) {
            const double normalized = ((double)values[index + 2] - (double)minimum) / span;
            put_f64_le(output, index * 8, normalized);
        }
    } else {
        const double mean = sum / (double)count;
        double squared_deviations = 0.0;
        for (size_t index = 0; index < count; ++index) {
            const double deviation = (double)values[index + 2] - mean;
            squared_deviations += deviation * deviation;
        }
        const double sample_deviation = sqrt(squared_deviations / (double)(count - 1));
        for (size_t index = 0; index < count; ++index) {
            const double standardized = ((double)values[index + 2] - mean) / sample_deviation;
            put_f64_le(output, index * 8, standardized);
        }
    }
    return (int64_t)output_bytes;
}
