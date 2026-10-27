#include <stddef.h>
#include <stdint.h>

enum { MAX_INPUT = 130, MAX_OUTPUT = 512, MAX_DIM = 8, INF = 1000000 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t min_plus_distance_product(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_DIM || m0 < 1 || m0 > MAX_DIM) return -1;
    const size_t n = (size_t)n0, m = (size_t)m0;
    if (length != 2 + 2 * n * m) return -1;
    for (size_t i = 2; i < length; ++i)
        if (input[i] < 0 || (input[i] > 1000 && input[i] != INF)) return -1;
    const size_t bytes = 8 * n * n;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;
    int64_t result[MAX_DIM * MAX_DIM];
    const int64_t *a = input + 2;
    const int64_t *b = input + 2 + n * m;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            int64_t best = INF;
            for (size_t k = 0; k < m; ++k) {
                const int64_t x = a[i * m + k], y = b[k * n + j];
                if (x != INF && y != INF && x + y < best) best = x + y;
            }
            result[i * n + j] = best;
        }
    }
    for (size_t i = 0; i < n * n; ++i) store_i64_le(output, 8 * i, result[i]);
    return (int64_t)bytes;
}
