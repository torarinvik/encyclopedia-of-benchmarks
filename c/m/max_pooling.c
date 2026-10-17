#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_N 16
#define MAX_INPUT_WORDS (3 + MAX_N * MAX_N)
#define MAX_PARSEABLE_INPUT_WORDS (MAX_INPUT_WORDS + 1)
#define MAX_OUTPUT_BYTES (8 * MAX_N * MAX_N)

int64_t max_pooling(const int32_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_WORDS) return -1;
    const int32_t n = input[0], size = input[1], stride = input[2];
    if (n < 1 || n > MAX_N || size < 1 || size > n || stride < 1 || stride > MAX_N ||
        length != 3 + (size_t)n * (size_t)n) return -1;
    const size_t cells = (size_t)n * (size_t)n;
    for (size_t i = 0; i < cells; ++i) if (input[3 + i] < -1000000 || input[3 + i] > 1000000) return -1;

    const int32_t out_side = (n - size) / stride + 1;
    const size_t output_count = (size_t)out_side * (size_t)out_side;
    const size_t bytes = output_count * 8;
    if (output == NULL || capacity < bytes) return -2;
    uint8_t buffer[MAX_OUTPUT_BYTES];
    size_t position = 0;
    for (int32_t row = 0; row < out_side; ++row) {
        for (int32_t col = 0; col < out_side; ++col) {
            const int32_t start_row = row * stride, start_col = col * stride;
            int32_t maximum = input[3 + (size_t)start_row * n + start_col];
            for (int32_t r = 0; r < size; ++r) {
                for (int32_t c = 0; c < size; ++c) {
                    const int32_t value = input[3 + (size_t)(start_row + r) * n + start_col + c];
                    if (value > maximum) maximum = value;
                }
            }
            const double result = (double)maximum;
            uint64_t bits;
            memcpy(&bits, &result, sizeof(bits));
            for (size_t byte = 0; byte < 8; ++byte) buffer[position++] = (uint8_t)(bits >> (8 * byte));
        }
    }
    for (size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return (int64_t)bytes;
}
