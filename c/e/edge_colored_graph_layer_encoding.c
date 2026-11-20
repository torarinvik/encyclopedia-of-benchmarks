#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define ECGL_MAX_N 8
#define ECGL_MAX_M 28
#define ECGL_MAX_D 3
#define ECGL_MAX_INPUT 97
#define ECGL_MAX_VERTICES (ECGL_MAX_N * ECGL_MAX_D)

static void ecgl_put(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t edge_colored_graph_layer_encoding(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > ECGL_MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], d64 = input[2], q64 = input[3];
    if (n64 < 1 || n64 > ECGL_MAX_N || m64 < 0 || m64 > ECGL_MAX_M
        || d64 < 1 || d64 > ECGL_MAX_D || q64 < 1 || q64 > 3) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    const size_t layers = (size_t)d64, classes = (size_t)q64;
    const size_t edge_offset = 4 + n;
    if (length != edge_offset + 3 * m) return -1;
    int64_t source_color[ECGL_MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        source_color[vertex] = input[4 + vertex];
        if (source_color[vertex] < 0 || source_color[vertex] >= q64) return -1;
    }
    uint8_t source_edges[ECGL_MAX_N][ECGL_MAX_N] = {{0}};
    size_t offset = edge_offset;
    for (size_t edge = 0; edge < m; ++edge) {
        int64_t u64 = input[offset], v64 = input[offset + 1], color64 = input[offset + 2];
        offset += 3;
        if (u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64
            || color64 < 1 || color64 >= (INT64_C(1) << d64)) return -1;
        size_t u = (size_t)u64, v = (size_t)v64;
        if (u > v) { size_t temp = u; u = v; v = temp; }
        if (source_edges[u][v] != 0) return -1;
        source_edges[u][v] = (uint8_t)color64;
    }

    const size_t nodes = n * layers;
    bool adjacency[ECGL_MAX_VERTICES][ECGL_MAX_VERTICES] = {{false}};
    for (size_t layer = 0; layer < layers; ++layer) {
        const uint8_t bit = (uint8_t)(1U << layer);
        for (size_t u = 0; u < n; ++u)
            for (size_t v = u + 1; v < n; ++v)
                if ((source_edges[u][v] & bit) != 0)
                    adjacency[layer * n + u][layer * n + v] = true;
    }
    for (size_t vertex = 0; vertex < n; ++vertex)
        for (size_t layer = 0; layer + 1 < layers; ++layer)
            adjacency[layer * n + vertex][(layer + 1) * n + vertex] = true;

    size_t edge_count = 0;
    for (size_t u = 0; u < nodes; ++u)
        for (size_t v = u + 1; v < nodes; ++v)
            if (adjacency[u][v]) ++edge_count;
    const size_t bytes = 8 * (2 + nodes + 2 * edge_count);
    if (output == NULL || capacity < bytes) return -2;

    ecgl_put(output, 0, (int64_t)nodes);
    ecgl_put(output, 8, (int64_t)edge_count);
    size_t word = 2;
    for (size_t layer = 0; layer < layers; ++layer)
        for (size_t vertex = 0; vertex < n; ++vertex)
            ecgl_put(output, 8 * word++, (int64_t)(layer * classes + (size_t)source_color[vertex]));
    for (size_t u = 0; u < nodes; ++u)
        for (size_t v = u + 1; v < nodes; ++v)
            if (adjacency[u][v]) {
                ecgl_put(output, 8 * word++, (int64_t)u);
                ecgl_put(output, 8 * word++, (int64_t)v);
            }
    return (int64_t)bytes;
}
