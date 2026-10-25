#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_INPUT_LENGTH (2 + 5 * MAX_N)
#define MAX_OPERAND 1000000

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int bounded_operand(int64_t value) {
    return value >= -MAX_OPERAND && value <= MAX_OPERAND;
}

int64_t tsvc_indexed_gather_scatter(const int64_t *input, size_t length,
                                    uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t mode = input[0];
    const int64_t n_raw = input[1];
    if ((mode != 491 && mode != 4113) || n_raw < 1 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    const size_t expected = 2 + (mode == 491 ? 5 : 4) * n;
    if (length != expected) return -1;

    const size_t index_start = 2;
    const size_t a_start = index_start + n;
    const size_t b_start = a_start + n;
    const size_t c_start = b_start + n;
    const size_t d_start = c_start + n;
    int64_t state[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        const int64_t index = input[index_start + i];
        if (index < 0 || index >= n_raw) return -1;
        state[i] = input[a_start + i];
        if (!bounded_operand(input[b_start + i]) ||
            !bounded_operand(input[c_start + i])) return -1;
        if (mode == 491 && !bounded_operand(input[d_start + i])) return -1;
    }
    if (output == NULL || output_capacity < 8 * n) return -2;

    for (size_t i = 0; i < n; ++i) {
        const size_t index = (size_t)input[index_start + i];
        if (mode == 491) {
            state[index] = input[b_start + i] + input[c_start + i] * input[d_start + i];
        } else {
            state[index] = input[b_start + index] + input[c_start + i];
        }
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, state[i]);
    return (int64_t)n;
}
