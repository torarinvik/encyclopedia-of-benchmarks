#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_INPUT 65

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[offset + b] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t metric_tsp_tree_doubling(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0];
    if (n64 < 1 || n64 > MAX_N || length != (size_t)(1 + n64 * n64)) return -1;
    const size_t n = (size_t)n64;
    int64_t d[MAX_N][MAX_N] = {{0}};
    for (size_t u = 0; u < n; ++u) for (size_t v = 0; v < n; ++v) {
        const int64_t w = input[1 + u * n + v];
        if (w < 0 || w > 10000 || (u == v && w != 0)) return -1;
        d[u][v] = w;
    }
    for (size_t u = 0; u < n; ++u) for (size_t v = u + 1; v < n; ++v)
        if (d[u][v] != d[v][u]) return -1;
    for (size_t u = 0; u < n; ++u) for (size_t v = 0; v < n; ++v)
        for (size_t k = 0; k < n; ++k) if (d[u][v] > d[u][k] + d[k][v]) return -1;
    const size_t output_bytes = 8 * (n + 2);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t processed[MAX_N][MAX_N] = {{0}}, tree[MAX_N][MAX_N] = {{0}};
    size_t parent[MAX_N], accepted = 0, edge_count = n * (n - 1) / 2;
    for (size_t i = 0; i < n; ++i) parent[i] = i;
    for (size_t step = 0; step < edge_count && accepted + 1 < n; ++step) {
        size_t bu = 0, bv = 0;
        int64_t bw = INT64_MAX;
        for (size_t u = 0; u < n; ++u) for (size_t v = u + 1; v < n; ++v)
            if (!processed[u][v] && d[u][v] < bw) { bw = d[u][v]; bu = u; bv = v; }
        processed[bu][bv] = 1;
        size_t ru = bu, rv = bv;
        while (parent[ru] != ru) ru = parent[ru];
        while (parent[rv] != rv) rv = parent[rv];
        if (ru != rv) { parent[rv] = ru; tree[bu][bv] = tree[bv][bu] = 1; ++accepted; }
    }
    size_t stack[MAX_N], top = 0, order[MAX_N], count = 0;
    uint8_t visited[MAX_N] = {0};
    stack[top++] = 0;
    while (top > 0) {
        const size_t v = stack[--top];
        if (visited[v]) continue;
        visited[v] = 1; order[count++] = v;
        for (size_t rev = n; rev > 0; --rev) {
            const size_t w = rev - 1;
            if (tree[v][w] && !visited[w]) stack[top++] = w;
        }
    }
    int64_t cost = 0;
    for (size_t i = 0; i + 1 < n; ++i) cost += d[order[i]][order[i + 1]];
    cost += d[order[n - 1]][0];
    store_i64_le(output, 0, cost);
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * (i + 1), (int64_t)order[i]);
    store_i64_le(output, 8 * (n + 1), 0);
    return (int64_t)output_bytes;
}
