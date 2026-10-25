#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_STRIDE 4
#define MAX_PHYSICAL_N (1 + (MAX_N - 1) * MAX_STRIDE)
#define MAX_INPUT_LENGTH (2 + MAX_PHYSICAL_N)
#define MAX_VALUE INT64_C(1000000)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s318_strided_absolute_maximum_with_index(
    const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    const int64_t stride_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_N || stride_raw < 1 || stride_raw > MAX_STRIDE) return -1;
    const size_t n = (size_t)n_raw;
    const size_t stride = (size_t)stride_raw;
    const size_t physical_n = 1 + (n - 1) * stride;
    if (length != 2 + physical_n) return -1;
    for (size_t i = 0; i < physical_n; ++i)
        if (input[i + 2] < -MAX_VALUE || input[i + 2] > MAX_VALUE) return -1;
    if (output == NULL || output_capacity < 16) return -2;

    int64_t maximum = input[2] < 0 ? -input[2] : input[2];
    size_t maximum_index = 0;
    for (size_t i = 1; i < n; ++i) {
        const int64_t value = input[2 + i * stride];
        const int64_t magnitude = value < 0 ? -value : value;
        if (magnitude > maximum) {
            maximum = magnitude;
            maximum_index = i;
        }
    }
    store_i64_le(output, 0, maximum);
    store_i64_le(output, 8, (int64_t)maximum_index);
    return 2;
}
