#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (2 + 3 * MAX_N)
#define MAX_VALUE 1000000

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int bounded_value(int64_t value) {
    return value >= -MAX_VALUE && value <= MAX_VALUE;
}

int64_t tsvc_s132_shifted_row_update(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 8 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 2 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    if (length != 2 + 3 * n) return -1;

    const size_t row_start = 1;
    const size_t target_start = row_start + n;
    const size_t b_start = target_start + n;
    const size_t c1_index = b_start + n;
    int64_t target[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        target[i] = input[target_start + i];
        if (!bounded_value(input[row_start + i]) || !bounded_value(target[i]) ||
            !bounded_value(input[b_start + i])) return -1;
    }
    const int64_t c1 = input[c1_index];
    if (!bounded_value(c1)) return -1;
    if (output == NULL || output_capacity < 8 * n) return -2;

    for (size_t i = 1; i < n; ++i)
        target[i] = input[row_start + i - 1] + input[b_start + i] * c1;
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, target[i]);
    return (int64_t)n;
}
