#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 32
#define MAX_INPUT_LENGTH 34

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

int64_t get_products_of_all_other_elements(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_ARRAY_LENGTH) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    int64_t result[MAX_ARRAY_LENGTH] = {0};
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < -2 || input[i + 1] > 2) return -1;
    }
    if (n < 2) return 0;
    const size_t output_bytes = n * 8;
    if (output == NULL || capacity < output_bytes) return -2;

    result[0] = 1;
    for (size_t i = 0; i < n - 1; ++i) result[i + 1] = input[i + 1] * result[i];
    int64_t suffix = 1;
    for (size_t i = n - 1; i > 0; --i) {
        const int64_t value = input[i + 1];
        result[i - 1] *= suffix * value;
        suffix *= value;
    }
    for (size_t i = 0; i < n; ++i) write_i64_le(output, i * 8, result[i]);
    return (int64_t)output_bytes;
}
