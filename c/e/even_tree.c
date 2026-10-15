#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_N 100

int64_t even_tree(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2) return INVALID_RESULT;
    const int64_t n_value = values[0], edge_value = values[1];
    if (n_value < 2 || n_value > MAX_N || n_value % 2 != 0 || edge_value != n_value - 1) return INVALID_RESULT;
    const size_t n = (size_t)n_value, edge_count = (size_t)edge_value;
    if (length != 2 + 2 * edge_count) return INVALID_RESULT;
    uint8_t adjacency[MAX_N][MAX_N] = {{0}};
    for (size_t i = 0; i < edge_count; ++i) {
        const int64_t u_value = values[2 + 2 * i], v_value = values[3 + 2 * i];
        if (u_value < 1 || u_value > n_value || v_value < 1 || v_value > n_value || u_value == v_value) return INVALID_RESULT;
        const size_t u = (size_t)(u_value - 1), v = (size_t)(v_value - 1);
        if (adjacency[u][v]) return INVALID_RESULT;
        adjacency[u][v] = adjacency[v][u] = 1;
    }
    int parent[MAX_N], stack[MAX_N], order[MAX_N];
    int64_t subtree[MAX_N];
    for (size_t i = 0; i < n; ++i) { parent[i] = -2; subtree[i] = 1; }
    parent[0] = -1;
    size_t top = 0, order_count = 0;
    stack[top++] = 0;
    while (top > 0) {
        const int u = stack[--top];
        order[order_count++] = u;
        for (size_t v = 0; v < n; ++v) if (adjacency[u][v] && parent[v] == -2) {
            parent[v] = u;
            stack[top++] = (int)v;
        }
    }
    if (order_count != n) return INVALID_RESULT;
    int64_t cuts = 0;
    for (size_t i = order_count; i-- > 0;) {
        const int u = order[i];
        if (parent[u] >= 0) subtree[parent[u]] += subtree[u];
        if (subtree[u] % 2 == 0) ++cuts;
    }
    return cuts - 1;
}
