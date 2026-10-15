#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t exponential_moving_average(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3) return -1;
    const int64_t window_value = input[0], count_value = input[1];
    if (window_value < 2 || window_value > 32 || count_value < 1 || count_value > 256) return -1;
    const size_t window = (size_t)window_value, count = (size_t)count_value;
    if (length != count + 2) return -1;
    for (size_t i = 0; i < count; ++i) if (input[2 + i] < -1000000 || input[2 + i] > 1000000) return -1;
    if (output == NULL || capacity < count * 8) return -2;
    const double alpha = 2.0 / (1.0 + (double)window);
    double average = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const double price = (double)input[2 + i];
        if (i == 0) average = price;
        else if (i <= window) average = (average + price) * 0.5;
        else average = (alpha * price) + ((1.0 - alpha) * average);
        put_f64_le(output, i * 8, average);
    }
    return (int64_t)(count * 8);
}
