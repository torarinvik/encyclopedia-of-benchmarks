#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + 5 * MAX_N)
#define MAX_VALUE INT64_C(2)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s243_ordered_lookahead_update(const int64_t *input, size_t length,
                                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 11 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 2 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    if (length != 1 + 5 * n) return -1;

    const size_t a_start = 1, b_start = a_start + n;
    const size_t c_start = b_start + n, d_start = c_start + n;
    const size_t e_start = d_start + n;
    int64_t a[MAX_N], b[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[a_start + i];
        b[i] = input[b_start + i];
        if (a[i] < -MAX_VALUE || a[i] > MAX_VALUE ||
            b[i] < -MAX_VALUE || b[i] > MAX_VALUE ||
            input[c_start + i] < -MAX_VALUE || input[c_start + i] > MAX_VALUE ||
            input[d_start + i] < -MAX_VALUE || input[d_start + i] > MAX_VALUE ||
            input[e_start + i] < -MAX_VALUE || input[e_start + i] > MAX_VALUE)
            return -1;
    }
    if (output == NULL || output_capacity < 16 * n) return -2;

    for (size_t i = 0; i + 1 < n; ++i) {
        const int64_t next_a = a[i + 1];
        const int64_t d_value = input[d_start + i];
        a[i] = b[i] + input[c_start + i] * d_value;
        b[i] = a[i] + d_value * input[e_start + i];
        a[i] = b[i] + next_a * d_value;
    }
    for (size_t i = 0; i < n; ++i) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
    }
    return (int64_t)(2 * n);
}
