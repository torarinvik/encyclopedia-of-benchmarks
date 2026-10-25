/* Clean-room bounded port of TSVC s252; see package README for provenance. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_INPUT_LENGTH = 1 + 2 * MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s252_adjacent_product_pair_sum(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 2 * n) return -1;
    int64_t b[MAX_N], c[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        b[i] = input[1 + i];
        c[i] = input[1 + n + i];
        if (b[i] < -2 || b[i] > 2 || c[i] < -2 || c[i] > 2) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    int64_t previous_product = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t product = b[i] * c[i];
        store_i64_le(output, 8 * i, product + previous_product);
        previous_product = product;
    }
    return (int64_t)n;
}
