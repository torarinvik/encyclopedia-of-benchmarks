/* Clean-room bounded port of GAPBS OrderedCount; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_INPUT = 1 + MAX_N * MAX_N };

int64_t gapbs_ordered_triangle_count(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0];
    if (n64 < 1 || n64 > MAX_N || length != 1 + (size_t)n64 * (size_t)n64) return -1;
    const size_t n = (size_t)n64;
    int64_t adjacency[MAX_N][MAX_N] = {{0}};
    int neighbors[MAX_N][MAX_N] = {{0}};
    int degree[MAX_N] = {0};
    for (size_t u = 0; u < n; ++u) {
        for (size_t v = 0; v < n; ++v) {
            const int64_t edge = input[1 + u * n + v];
            if (edge != 0 && edge != 1) return -1;
            if (u == v && edge != 0) return -1;
            adjacency[u][v] = edge;
        }
    }
    for (size_t u = 0; u < n; ++u)
        for (size_t v = u + 1; v < n; ++v)
            if (adjacency[u][v] != adjacency[v][u]) return -1;
    for (size_t u = 0; u < n; ++u)
        for (size_t v = 0; v < n; ++v)
            if (adjacency[u][v] != 0) neighbors[u][degree[u]++] = (int)v;

    int64_t triangles = 0;
    for (size_t u = 0; u < n; ++u) {
        for (int vi = 0; vi < degree[u]; ++vi) {
            const int v = neighbors[u][vi];
            if ((size_t)v > u) break;
            int edge_pos = 0;
            for (int wi = 0; wi < degree[u]; ++wi) {
                const int w = neighbors[u][wi];
                if (w > v) break;
                while (edge_pos < degree[v] && neighbors[v][edge_pos] < w) ++edge_pos;
                if (edge_pos < degree[v] && neighbors[v][edge_pos] == w) ++triangles;
            }
        }
    }
    return triangles;
}
