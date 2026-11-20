#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_M = 128, MAX_INPUT = 259, MAX_ARCS = 2 * MAX_M };

int64_t cactus_graph_recognition(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MAX_N || m_value < 0 || m_value > MAX_M) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + 2 * m) return -1;

    bool edge_seen[MAX_N][MAX_N] = {{false}};
    int32_t head[MAX_N], arc_to[MAX_ARCS], arc_edge[MAX_ARCS], next_arc[MAX_ARCS];
    for (size_t u = 0; u < n; ++u) head[u] = -1;
    size_t arc_count = 0;
    for (size_t e = 0; e < m; ++e) {
        const int64_t u_value = input[2 + 2 * e], v_value = input[3 + 2 * e];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        const size_t u = (size_t)u_value, v = (size_t)v_value;
        if (edge_seen[u][v]) return -1;
        edge_seen[u][v] = edge_seen[v][u] = true;
        arc_to[arc_count] = (int32_t)v; arc_edge[arc_count] = (int32_t)e;
        next_arc[arc_count] = head[u]; head[u] = (int32_t)arc_count++;
        arc_to[arc_count] = (int32_t)u; arc_edge[arc_count] = (int32_t)e;
        next_arc[arc_count] = head[v]; head[v] = (int32_t)arc_count++;
    }

    int32_t state[MAX_N] = {0}, parent[MAX_N], parent_edge[MAX_N], depth[MAX_N], cursor[MAX_N], stack[MAX_N];
    int32_t cycle_of[MAX_M], cycle_vertices[MAX_N] = {0};
    bool used[MAX_M] = {false};
    for (size_t u = 0; u < n; ++u) { parent[u] = -1; parent_edge[u] = -1; depth[u] = 0; cursor[u] = -1; }
    for (size_t e = 0; e < m; ++e) cycle_of[e] = -1;

    int32_t cycles = 0;
    bool edge_cactus = true, vertex_cactus = true;
    for (size_t root = 0; root < n && edge_cactus; ++root) {
        if (state[root] != 0) continue;
        size_t top = 0;
        state[root] = 1; cursor[root] = head[root]; stack[top++] = (int32_t)root;
        while (top > 0 && edge_cactus) {
            const int32_t u = stack[top - 1];
            const int32_t arc = cursor[u];
            if (arc < 0) { state[u] = 2; --top; continue; }
            cursor[u] = next_arc[arc];
            const int32_t e = arc_edge[arc];
            if (used[e]) continue;
            used[e] = true;
            const int32_t v = arc_to[arc];
            if (state[v] == 0) {
                parent[v] = u; parent_edge[v] = e; depth[v] = depth[u] + 1;
                state[v] = 1; cursor[v] = head[v]; stack[top++] = v;
            } else if (state[v] == 1 && depth[v] < depth[u]) {
                int32_t x = u;
                while (x != v) {
                    const int32_t tree_edge = parent_edge[x];
                    if (tree_edge < 0 || cycle_of[tree_edge] != -1) { edge_cactus = false; break; }
                    x = parent[x];
                }
                if (!edge_cactus) break;
                x = u;
                ++cycle_vertices[x];
                if (cycle_vertices[x] > 1) vertex_cactus = false;
                while (x != v) {
                    const int32_t tree_edge = parent_edge[x];
                    cycle_of[tree_edge] = cycles;
                    x = parent[x];
                    ++cycle_vertices[x];
                    if (cycle_vertices[x] > 1) vertex_cactus = false;
                }
                cycle_of[e] = cycles;
                ++cycles;
            }
        }
    }
    if (!edge_cactus) return 0;
    return (int64_t)(4 * cycles + (vertex_cactus ? 2 : 0) + 1);
}
