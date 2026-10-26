#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 2 + 2 * MAX_M };

static void compress_components(int n, int *component) {
    for (int node = 0; node < n; ++node)
        while (component[node] != component[component[node]])
            component[node] = component[component[node]];
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gapbs_shiloach_vishkin_components(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;
    uint8_t adjacency[MAX_N][MAX_N] = {{0}};
    for (int edge = 0; edge < m; ++edge) {
        const size_t pos = 2 + 2 * (size_t)edge;
        const int64_t u = input[pos], v = input[pos + 1];
        if (u < 0 || v <= u || v >= n64 || adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
    }
    const size_t output_bytes = 8 * (size_t)n;
    if (output == NULL || capacity < output_bytes) return -2;
    int component[MAX_N];
    for (int node = 0; node < n; ++node) component[node] = node;

    int changed = 1;
    size_t rounds = 0;
    const size_t round_limit = (size_t)n * (size_t)n + 1;
    while (changed && rounds < round_limit) {
        changed = 0;
        for (int u = 0; u < n; ++u) {
            for (int v = 0; v < n; ++v) {
                if (!adjacency[u][v]) continue;
                const int component_u = component[u], component_v = component[v];
                if (component_u == component_v) continue;
                const int high = component_u > component_v ? component_u : component_v;
                const int low = component_u + (component_v - high);
                if (component[high] == high) {
                    changed = 1;
                    component[high] = low;
                }
            }
        }
        compress_components(n, component);
        ++rounds;
    }
    if (changed) return -1;
    for (int node = 0; node < n; ++node)
        store_i64_le(output, 8 * (size_t)node, component[node]);
    return (int64_t)output_bytes;
}
