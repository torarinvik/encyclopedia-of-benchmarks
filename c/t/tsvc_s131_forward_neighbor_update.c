#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (2 + 2 * MAX_N)
#define MAX_VALUE 1000000
#define MAX_PASSES 32

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int bounded_value(int64_t value) {
    return value >= -MAX_VALUE && value <= MAX_VALUE;
}

int64_t tsvc_s131_forward_neighbor_update(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0], passes_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_N || passes_raw < 1 || passes_raw > MAX_PASSES) return -1;
    const size_t n = (size_t)n_raw;
    if (length != 2 + 2 * n) return -1;

    int64_t a[MAX_N], b[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[2 + i];
        b[i] = input[2 + n + i];
        if (!bounded_value(a[i]) || !bounded_value(b[i])) return -1;
    }
    if (output == NULL || output_capacity < 8 * n) return -2;

    for (int64_t pass = 0; pass < passes_raw; ++pass)
        for (size_t i = 0; i + 1 < n; ++i)
            a[i] = a[i + 1] + b[i];
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)n;
}
