/* Clean-room bounded edge-peeling truss decomposition. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 120, MAX_VALID_INPUT = 242, MAX_PARSEABLE_INPUT = 243 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t k_truss_edge_peeling_decomposition(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64 || length > MAX_VALID_INPUT) return -1;
    const int n = (int)n64, m = (int)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int edge_index[MAX_N][MAX_N];
    int edge_u[MAX_M], edge_v[MAX_M], support[MAX_M];
    uint8_t alive[MAX_M] = {0};
    int64_t trussness[MAX_M] = {0};
    for (int u = 0; u < MAX_N; ++u)
        for (int v = 0; v < MAX_N; ++v) edge_index[u][v] = -1;
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * (size_t)edge];
        const int64_t v64 = input[3 + 2 * (size_t)edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const int u = (int)u64, v = (int)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
        edge_index[u][v] = edge_index[v][u] = edge;
        edge_u[edge] = u;
        edge_v[edge] = v;
        support[edge] = 0;
        alive[edge] = 1;
    }
    for (int u = 0; u < n; ++u)
        for (int v = u + 1; v < n; ++v)
            for (int w = v + 1; w < n; ++w)
                if (adjacent[u][v] && adjacent[u][w] && adjacent[v][w]) {
                    ++support[edge_index[u][v]];
                    ++support[edge_index[u][w]];
                    ++support[edge_index[v][w]];
                }
    const size_t output_bytes = 8 * (size_t)m;
    if (output == NULL || capacity < output_bytes) return -2;

    int remaining = m, level = 0;
    while (remaining > 0) {
        int selected = -1;
        for (int edge = 0; edge < m; ++edge)
            if (alive[edge] && (selected < 0 || support[edge] < support[selected])) selected = edge;
        if (support[selected] > level) level = support[selected];
        trussness[selected] = (int64_t)level + 2;
        alive[selected] = 0;
        --remaining;
        const int u = edge_u[selected], v = edge_v[selected];
        for (int w = 0; w < n; ++w) {
            if (w == u || w == v || !adjacent[u][w] || !adjacent[v][w]) continue;
            const int first = edge_index[u][w], second = edge_index[v][w];
            if (alive[first] && alive[second]) {
                if (support[first] > level) --support[first];
                if (support[second] > level) --support[second];
            }
        }
    }
    for (int edge = 0; edge < m; ++edge)
        store_i64_le(output, 8 * (size_t)edge, trussness[edge]);
    return (int64_t)output_bytes;
}
