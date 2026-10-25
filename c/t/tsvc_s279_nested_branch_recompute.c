// Clean-room bounded port of TSVC s279; see package README for provenance.
#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_PASSES 8
#define MAX_INPUT_LENGTH (2 + 5 * MAX_N)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t tsvc_s279_nested_branch_recompute(const int64_t *input, size_t length,
                                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 7 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0], passes_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_N || passes_raw < 1 || passes_raw > MAX_PASSES) return -1;
    const size_t n = (size_t)n_raw, passes = (size_t)passes_raw;
    if (length != 2 + 5 * n) return -1;
    for (size_t i = 2; i < length; ++i)
        if (input[i] < -2 || input[i] > 2) return -1;
    if (output == NULL || output_capacity < 24 * n) return -2;

    const size_t a_start = 2, b_start = a_start + n, c_start = b_start + n;
    const size_t d_start = c_start + n, e_start = d_start + n;
    int64_t a[MAX_N], b[MAX_N], c[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[a_start + i];
        b[i] = input[b_start + i];
        c[i] = input[c_start + i];
    }
    for (size_t pass = 0; pass < passes; ++pass) {
        for (size_t i = 0; i < n; ++i) {
            if (a[i] > 0) {
                c[i] = -c[i] + input[e_start + i] * input[e_start + i];
            } else {
                b[i] = -b[i] + input[d_start + i] * input[d_start + i];
                if (b[i] > a[i]) c[i] += input[d_start + i] * input[e_start + i];
            }
            a[i] = b[i] + c[i] * input[d_start + i];
        }
    }
    for (size_t i = 0; i < n; ++i) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
        store_i64_le(output, 8 * (2 * n + i), c[i]);
    }
    return (int64_t)(3 * n);
}
