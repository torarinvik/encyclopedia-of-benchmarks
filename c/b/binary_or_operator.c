#include <stddef.h>
#include <stdint.h>

int64_t binary_or_operator(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 2 || input[0] < 0 || input[0] > INT32_MAX || input[1] < 0 || input[1] > INT32_MAX) return -1;
    uint64_t a = (uint64_t)input[0], b = (uint64_t)input[1];
    size_t width = 1;
    uint64_t largest = a > b ? a : b;
    while (largest > 1) { ++width; largest >>= 1; }
    size_t output_length = width + 2;
    if (capacity < output_length || output == NULL) return -2;
    uint64_t result = a | b;
    output[0] = '0'; output[1] = 'b';
    for (size_t i = 0; i < width; ++i) {
        size_t bit = width - 1 - i;
        output[2 + i] = (uint8_t)(((result >> bit) & 1) ? '1' : '0');
    }
    return (int64_t)output_length;
}
