/* Clean-room bounded GBBS Shiloach-Vishkin spanning-forest profile. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_M = 24, MAX_INPUT = 2 + 2 * MAX_M };

static size_t find_root(size_t parent[MAX_N], size_t vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

int64_t gbbs_shiloach_vishkin_spanning_forest(const int64_t *input, size_t length,
                                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t seen[MAX_N][MAX_N] = {{0}};
    size_t edge_u[MAX_M], edge_v[MAX_M];
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (seen[u][v]) return -1;
        seen[u][v] = 1;
        edge_u[edge] = u;
        edge_v[edge] = v;
    }
    if (output == NULL || capacity < m) return -2;

    size_t parent[MAX_N], previous[MAX_N], next_parent[MAX_N], best_lower[MAX_N];
    uint8_t selected[MAX_M] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) parent[vertex] = vertex;
    for (size_t round = 0; round < n; ++round) {
        for (size_t vertex = 0; vertex < n; ++vertex) {
            previous[vertex] = find_root(parent, vertex);
            next_parent[vertex] = previous[vertex];
            best_lower[vertex] = n;
        }
        for (size_t edge = 0; edge < m; ++edge) {
            const size_t root_u = previous[edge_u[edge]], root_v = previous[edge_v[edge]];
            if (root_u == root_v) continue;
            const size_t lower = root_u < root_v ? root_u : root_v;
            const size_t higher = root_u < root_v ? root_v : root_u;
            if (previous[higher] == higher && lower < best_lower[higher])
                best_lower[higher] = lower;
        }
        uint8_t changed = 0;
        for (size_t higher = 0; higher < n; ++higher) {
            const size_t lower = best_lower[higher];
            if (lower == n) continue;
            next_parent[higher] = lower;
            changed = 1;
            for (size_t edge = 0; edge < m; ++edge) {
                const size_t root_u = previous[edge_u[edge]], root_v = previous[edge_v[edge]];
                if ((root_u == higher && root_v == lower) ||
                    (root_u == lower && root_v == higher)) {
                    selected[edge] = 1;
                    break;
                }
            }
        }
        for (size_t vertex = 0; vertex < n; ++vertex)
            parent[vertex] = find_root(next_parent, vertex);
        if (!changed) break;
    }
    for (size_t edge = 0; edge < m; ++edge) output[edge] = selected[edge];
    return (int64_t)m;
}
