#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void put_f64_le(double value, uint8_t *output, size_t offset) {
    uint64_t bits; memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}
static void put_i64_le(int64_t value, uint8_t *output, size_t offset) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t exponential_moving_average_java_stream(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 2 || input[1] < 0 || input[1] > 256 || length != 2 + (size_t)input[1]) return -1;
    if (input[0] < -1000000 || input[0] > 1000000) return -1;
    double mean = (double)input[0], variance = 0.0;
    for (size_t index = 0; index < (size_t)input[1]; ++index) {
        if (input[index + 2] < -1000000 || input[index + 2] > 1000000) return -1;
        const double value = (double)input[index + 2];
        const double deviation = value - mean;
        mean += 0.25 * deviation;
        variance = 0.75 * (variance + 0.25 * deviation * deviation);
    }
    if (!output || capacity < 24) return -2;
    put_f64_le(mean, output, 0); put_f64_le(variance, output, 8); put_i64_le(input[1], output, 16);
    return 24;
}
