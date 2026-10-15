#include <stddef.h>
#include <stdint.h>

int64_t circular_convolution(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 4) return -1;
    const int64_t raw_a_length = values[0];
    const int64_t raw_b_length = values[1];
    if (raw_a_length < 1 || raw_a_length > 8 || raw_b_length < 1 || raw_b_length > 8) return -1;
    const size_t a_length = (size_t)raw_a_length;
    const size_t b_length = (size_t)raw_b_length;
    if (length != 2 + a_length + b_length) return -1;
    for (size_t i = 0; i < a_length + b_length; ++i) {
        if (values[2 + i] < -2 || values[2 + i] > 2) return -1;
    }
    const size_t n = a_length > b_length ? a_length : b_length;
    if (output == NULL || capacity < n) return -2;

    for (size_t k = 0; k < n; ++k) {
        int64_t sum = 0;
        for (size_t i = 0; i < n; ++i) {
            const size_t b_index = (k + n - i) % n;
            const int64_t a_value = i < a_length ? values[2 + i] : 0;
            const int64_t b_value = b_index < b_length ? values[2 + a_length + b_index] : 0;
            sum += a_value * b_value;
        }
        output[k] = (uint8_t)(sum < 0 ? sum + 256 : sum);
    }
    return (int64_t)n;
}
