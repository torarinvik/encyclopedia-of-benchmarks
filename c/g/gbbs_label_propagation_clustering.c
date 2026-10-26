/* Clean-room bounded GBBS label-propagation profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 2 + 2 * MAX_M };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gbbs_label_propagation_clustering(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
    }
    const size_t output_bytes = 8 * n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t labels[MAX_N] = {0};
    for (size_t v = 0; v < n; ++v) labels[v] = (int64_t)v;
    /* One deterministic asynchronous source sweep in increasing vertex order. */
    for (size_t u = 0; u < n; ++u) {
        size_t frequency[MAX_N] = {0};
        size_t degree = 0;
        for (size_t v = 0; v < n; ++v) if (adjacent[u][v]) {
            ++frequency[(size_t)labels[v]];
            ++degree;
        }
        if (degree == 0) continue;
        size_t best_label = 0, best_frequency = 0;
        for (size_t label = 0; label < n; ++label)
            if (frequency[label] > best_frequency ||
                (frequency[label] == best_frequency && frequency[label] != 0 && label > best_label)) {
                best_frequency = frequency[label];
                best_label = label;
            }
        labels[u] = (int64_t)best_label;
    }
    for (size_t v = 0; v < n; ++v) store_i64_le(output, 8 * v, labels[v]);
    return (int64_t)output_bytes;
}
