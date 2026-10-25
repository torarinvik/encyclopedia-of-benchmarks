#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + MAX_N)
#define MAX_VALUE INT64_C(1000000)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s291_cyclic_neighbor_average(const int64_t *input, size_t length,
                                          uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 2 || n_raw > MAX_N || length != 1 + (size_t)n_raw) return -1;
    const size_t n = (size_t)n_raw;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < -MAX_VALUE || input[i + 1] > MAX_VALUE) return -1;
    if (output == NULL || output_capacity < 8 * n) return -2;

    for (size_t i = 0; i < n; ++i) {
        const size_t previous = i == 0 ? n - 1 : i - 1;
        store_i64_le(output, 8 * i, input[i + 1] + input[previous + 1]);
    }
    return (int64_t)n;
}
