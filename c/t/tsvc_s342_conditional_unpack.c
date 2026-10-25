#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + 2 * MAX_N)
#define MAX_VALUE INT64_C(2)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s342_conditional_unpack(const int64_t *input, size_t length,
                                    uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    if (length != 1 + 2 * n) return -1;

    const size_t a_start = 1, b_start = a_start + n;
    int64_t a[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[a_start + i];
        if (a[i] < -MAX_VALUE || a[i] > MAX_VALUE ||
            input[b_start + i] < -MAX_VALUE || input[b_start + i] > MAX_VALUE)
            return -1;
    }
    if (output == NULL || output_capacity < 8 * n) return -2;

    size_t packed_index = 0;
    for (size_t i = 0; i < n; ++i) {
        if (a[i] > 0) a[i] = input[b_start + packed_index++];
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)n;
}
