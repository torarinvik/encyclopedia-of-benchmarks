#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, INF = 1000000 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t apsp_min_plus_repeated_squaring(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 65) return -1;
    const int64_t n0 = input[0];
    if (n0 < 1 || n0 > MAX_N) return -1;
    const size_t n = (size_t)n0;
    if (length != 1 + n * n) return -1;
    int64_t current[MAX_N * MAX_N], next[MAX_N * MAX_N];
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            const int64_t value = input[1 + i * n + j];
            if ((i == j && value != 0)
                || (i != j && value != INF && (value < 1 || value > 1000))) return -1;
            current[i * n + j] = value;
        }
    }
    size_t edge_bound = 1;
    while (edge_bound < n - 1) {
        for (size_t i = 0; i < n; ++i) {
            for (size_t j = 0; j < n; ++j) {
                int64_t best = INF;
                for (size_t k = 0; k < n; ++k) {
                    const int64_t left = current[i * n + k];
                    const int64_t right = current[k * n + j];
                    if (left != INF && right != INF && left + right < best)
                        best = left + right;
                }
                next[i * n + j] = best;
            }
        }
        for (size_t index = 0; index < n * n; ++index) current[index] = next[index];
        edge_bound *= 2;
    }
    const size_t bytes = 8 * n * n;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t index = 0; index < n * n; ++index)
        store_i64_le(output, 8 * index, current[index]);
    return (int64_t)bytes;
}
