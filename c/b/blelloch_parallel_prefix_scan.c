#include <stddef.h>
#include <stdint.h>

enum { MAX_ITEMS = 64, MAX_INPUT_WORDS = 66, MAX_OUTPUT_BYTES = 512 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t blelloch_parallel_prefix_scan(const int64_t *input, size_t length,
                                      uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int64_t n64 = input[0];
    if (n64 < 1 || n64 > MAX_ITEMS) return -1;
    const size_t n = (size_t)n64;
    if (length != n + 1) return -1;

    int64_t tree[MAX_ITEMS] = {0};
    size_t padded = 1;
    while (padded < n) padded <<= 1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[i + 1];
        if (value < -INT64_C(1000000) || value > INT64_C(1000000)) return -1;
        tree[i] = value;
    }
    if (output == NULL || output_capacity < n * 8) return -2;

    for (size_t stride = 2; stride <= padded; stride <<= 1) {
        const size_t half = stride >> 1;
        for (size_t right = stride - 1; right < padded; right += stride)
            tree[right] += tree[right - half];
    }
    tree[padded - 1] = 0;
    for (size_t stride = padded; stride >= 2; stride >>= 1) {
        const size_t half = stride >> 1;
        for (size_t right = stride - 1; right < padded; right += stride) {
            const size_t left = right - half;
            const int64_t partial = tree[left];
            tree[left] = tree[right];
            tree[right] += partial;
        }
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, i * 8, tree[i]);
    return (int64_t)(n * 8);
}
