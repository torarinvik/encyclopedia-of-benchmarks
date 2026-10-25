/* Clean-room port of TSVC s128; provenance and rights are in the package README. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_INPUT_LENGTH = 1 + 5 * MAX_N, MAX_OUTPUT_BYTES = 24 * MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s128_strided_coupled_update(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0], b_count = 2 * n;
    if (length != 1 + 5 * n) return -1;
    int64_t a[MAX_N], b[2 * MAX_N], c[2 * MAX_N], d[MAX_N];
    for (size_t i = 0; i < b_count; ++i) {
        b[i] = input[1 + i];
        c[i] = input[1 + b_count + i];
        if (b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100) return -1;
    }
    for (size_t i = 0; i < n; ++i) {
        d[i] = input[1 + 2 * b_count + i];
        if (d[i] < -100 || d[i] > 100) return -1;
    }
    const size_t output_values = 3 * n, output_bytes = 8 * output_values;
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t j = -1;
    for (size_t i = 0; i < n; ++i) {
        const size_t k = (size_t)(j + 1);
        a[i] = b[k] - d[i];
        j = (int64_t)k + 1;
        b[k] = a[i] + c[k];
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    for (size_t i = 0; i < b_count; ++i) store_i64_le(output, 8 * (n + i), b[i]);
    return (int64_t)output_values;
}
