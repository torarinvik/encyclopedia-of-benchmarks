#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_PASSES 8
#define MAX_INPUT_LENGTH (3 + 5 * MAX_N)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t tsvc_s272_threshold_dual_accumulate(const int64_t *input, size_t length,
                                            uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 8 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0], passes_raw = input[1], threshold = input[2];
    if (n_raw < 1 || n_raw > MAX_N || passes_raw < 1 || passes_raw > MAX_PASSES ||
        threshold < -2 || threshold > 2) return -1;
    const size_t n = (size_t)n_raw, passes = (size_t)passes_raw;
    if (length != 3 + 5 * n) return -1;
    for (size_t i = 3; i < length; ++i)
        if (input[i] < -2 || input[i] > 2) return -1;
    if (output == NULL || output_capacity < 16 * n) return -2;

    const size_t a_start = 3, b_start = a_start + n, c_start = b_start + n;
    const size_t d_start = c_start + n, e_start = d_start + n;
    int64_t a[MAX_N], b[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[a_start + i];
        b[i] = input[b_start + i];
    }
    for (size_t pass = 0; pass < passes; ++pass) {
        for (size_t i = 0; i < n; ++i) {
            if (input[e_start + i] >= threshold) {
                a[i] += input[c_start + i] * input[d_start + i];
                b[i] += input[c_start + i] * input[c_start + i];
            }
        }
    }
    for (size_t i = 0; i < n; ++i) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
    }
    return (int64_t)(2 * n);
}
