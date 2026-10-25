#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + 3 * MAX_N)
#define MAX_VALUE INT64_C(2)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s319_coupled_reductions(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    if (length != 1 + 3 * n) return -1;

    const size_t c_start = 1, d_start = c_start + n, e_start = d_start + n;
    for (size_t i = 0; i < n; ++i) {
        if (input[c_start + i] < -MAX_VALUE || input[c_start + i] > MAX_VALUE ||
            input[d_start + i] < -MAX_VALUE || input[d_start + i] > MAX_VALUE ||
            input[e_start + i] < -MAX_VALUE || input[e_start + i] > MAX_VALUE) return -1;
    }
    const size_t value_count = 2 * n + 1;
    if (output == NULL || output_capacity < 8 * value_count) return -2;

    int64_t total = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t a_value = input[c_start + i] + input[d_start + i];
        const int64_t b_value = input[c_start + i] + input[e_start + i];
        store_i64_le(output, 8 * i, a_value);
        store_i64_le(output, 8 * (n + i), b_value);
        total += a_value;
        total += b_value;
    }
    store_i64_le(output, 8 * (2 * n), total);
    return (int64_t)value_count;
}
