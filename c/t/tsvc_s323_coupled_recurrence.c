#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + 5 * MAX_N)

static int bounded_value(int64_t value) { return value >= -1 && value <= 1; }

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s323_coupled_recurrence(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 11 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 2 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    if (length != 1 + 5 * n) return -1;

    const size_t a_start = 1, b_start = a_start + n, c_start = b_start + n;
    const size_t d_start = c_start + n, e_start = d_start + n;
    int64_t a[MAX_N], b[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[a_start + i];
        b[i] = input[b_start + i];
        if (!bounded_value(a[i]) || !bounded_value(b[i]) ||
            !bounded_value(input[c_start + i]) || !bounded_value(input[d_start + i]) ||
            !bounded_value(input[e_start + i])) return -1;
    }
    if (output == NULL || output_capacity < 16 * n) return -2;

    for (size_t i = 1; i < n; ++i) {
        a[i] = b[i - 1] + input[c_start + i] * input[d_start + i];
        b[i] = a[i] + input[c_start + i] * input[e_start + i];
    }
    for (size_t i = 0; i < n; ++i) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
    }
    return (int64_t)(2 * n);
}
