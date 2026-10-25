#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_TRIANGLE (MAX_N * (MAX_N + 1) / 2)
#define MAX_INPUT_LENGTH (2 + MAX_TRIANGLE + MAX_N * MAX_N)
#define MAX_VALUE 1000000
#define MAX_ROUNDS 32

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int bounded_value(int64_t value) {
    return value >= -MAX_VALUE && value <= MAX_VALUE;
}

int64_t tsvc_s141_packed_symmetric_update(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0], rounds_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_N || rounds_raw < 1 || rounds_raw > MAX_ROUNDS) return -1;
    const size_t n = (size_t)n_raw;
    const size_t triangle = n * (n + 1) / 2;
    const size_t matrix_start = 2 + triangle;
    if (length != matrix_start + n * n) return -1;

    int64_t packed[MAX_TRIANGLE];
    for (size_t p = 0; p < triangle; ++p) {
        packed[p] = input[2 + p];
        if (!bounded_value(packed[p])) return -1;
    }
    for (size_t p = 0; p < n * n; ++p)
        if (!bounded_value(input[matrix_start + p])) return -1;
    if (output == NULL || output_capacity < 8 * triangle) return -2;

    for (size_t round = 0; round < (size_t)rounds_raw; ++round) {
        for (size_t i = 0; i < n; ++i) {
            for (size_t j = i; j < n; ++j) {
                const size_t k = j * (j + 1) / 2 + i;
                packed[k] += input[matrix_start + j * n + i];
            }
        }
    }
    for (size_t p = 0; p < triangle; ++p) store_i64_le(output, 8 * p, packed[p]);
    return (int64_t)triangle;
}
