#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_M 64
#define MAX_INPUT (2 + 3 * MAX_M)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gbbs_maximal_matching(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 3 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    int rank_seen[MAX_M] = {0}, adjacency[MAX_N][MAX_N] = {{0}};
    size_t order[MAX_M] = {0};
    const size_t edge_start = 2 + m;
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t rank64 = input[2 + edge];
        if (rank64 < 0 || rank64 >= m64 || rank_seen[rank64]) return -1;
        rank_seen[rank64] = 1;
        order[rank64] = edge;
        const int64_t u64 = input[edge_start + 2 * edge];
        const int64_t v64 = input[edge_start + 2 * edge + 1];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
    }
    const size_t output_bytes = 8 * m;
    if (output == NULL || capacity < output_bytes) return -2;
    int matched[MAX_N] = {0}, selected[MAX_M] = {0};
    for (size_t rank = 0; rank < m; ++rank) {
        const size_t edge = order[rank];
        const size_t u = (size_t)input[edge_start + 2 * edge];
        const size_t v = (size_t)input[edge_start + 2 * edge + 1];
        if (!matched[u] && !matched[v]) {
            selected[edge] = 1;
            matched[u] = matched[v] = 1;
        }
    }
    for (size_t edge = 0; edge < m; ++edge)
        store_i64_le(output, 8 * edge, selected[edge]);
    return (int64_t)output_bytes;
}
