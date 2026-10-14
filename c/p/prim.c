#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define PRIM_MAX_VERTICES 64
#define PRIM_MAX_EDGES 4096

int64_t prim(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 2 + 3 * PRIM_MAX_EDGES) return -2;
    if (values[0] < 0 || values[0] > PRIM_MAX_VERTICES || values[1] < 0 || values[1] > PRIM_MAX_EDGES) return -2;
    const size_t vertices = (size_t)values[0];
    const size_t edges = (size_t)values[1];
    if (length != 2 + 3 * edges || (vertices == 0 && edges != 0)) return -2;
    if (vertices == 0) return 0;

    bool present[PRIM_MAX_VERTICES * PRIM_MAX_VERTICES] = {false};
    int64_t weight[PRIM_MAX_VERTICES * PRIM_MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t u_value = values[2 + 3 * edge];
        const int64_t v_value = values[3 + 3 * edge];
        const int64_t cost = values[4 + 3 * edge];
        if (u_value < 0 || v_value < 0 || (uint64_t)u_value >= vertices ||
            (uint64_t)v_value >= vertices || cost < 0 || cost > INT64_C(2147483647)) return -2;
        const size_t u = (size_t)u_value, v = (size_t)v_value;
        if (u == v) continue;
        const size_t uv = u * PRIM_MAX_VERTICES + v, vu = v * PRIM_MAX_VERTICES + u;
        if (!present[uv] || cost < weight[uv]) {
            present[uv] = present[vu] = true;
            weight[uv] = weight[vu] = cost;
        }
    }

    bool in_tree[PRIM_MAX_VERTICES] = {false};
    bool has_best[PRIM_MAX_VERTICES] = {false};
    int64_t best[PRIM_MAX_VERTICES] = {0};
    has_best[0] = true;
    int64_t total = 0;
    for (size_t step = 0; step < vertices; ++step) {
        size_t selected = vertices;
        for (size_t vertex = 0; vertex < vertices; ++vertex) {
            if (!in_tree[vertex] && has_best[vertex] &&
                (selected == vertices || best[vertex] < best[selected])) selected = vertex;
        }
        if (selected == vertices) return -1;
        in_tree[selected] = true;
        total += best[selected];
        for (size_t vertex = 0; vertex < vertices; ++vertex) {
            const size_t slot = selected * PRIM_MAX_VERTICES + vertex;
            if (!in_tree[vertex] && present[slot] && (!has_best[vertex] || weight[slot] < best[vertex])) {
                has_best[vertex] = true;
                best[vertex] = weight[slot];
            }
        }
    }
    return total;
}
