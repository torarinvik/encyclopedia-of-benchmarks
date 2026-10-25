#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + MAX_N)
#define MAX_VALUE INT64_C(1000000)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tsvc_s315_maximum_with_index(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > MAX_N) return -1;
    const size_t n = (size_t)n_raw;
    if (length != 1 + n) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < -MAX_VALUE || input[i + 1] > MAX_VALUE) return -1;
    if (output == NULL || output_capacity < 16) return -2;

    int64_t maximum = input[1];
    size_t maximum_index = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[i + 1];
        if (value > maximum) {
            maximum = value;
            maximum_index = i;
        }
    }
    store_i64_le(output, 0, maximum);
    store_i64_le(output, 8, (int64_t)maximum_index);
    return 2;
}
