#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 16
#define MAX_INPUT 34
static void chromatic_poly(const uint32_t adjacency[MAX_VERTICES], size_t n,
                           int64_t result[MAX_VERTICES + 1]) {
    size_t edge_u = n, edge_v = n;
    for (size_t u = 0; u < n && edge_u == n; ++u) {
        for (size_t v = u + 1; v < n; ++v) {
            if (adjacency[u] & (UINT32_C(1) << v)) { edge_u = u; edge_v = v; break; }
        }
    }
    for (size_t i = 0; i <= MAX_VERTICES; ++i) result[i] = 0;
    if (edge_u == n) { result[n] = 1; return; }

    uint32_t deleted[MAX_VERTICES] = {0};
    for (size_t i = 0; i < MAX_VERTICES; ++i) deleted[i] = adjacency[i];
    deleted[edge_u] &= ~(UINT32_C(1) << edge_v);
    deleted[edge_v] &= ~(UINT32_C(1) << edge_u);
    int64_t without_edge[MAX_VERTICES + 1];
    chromatic_poly(deleted, n, without_edge);

    uint32_t contracted[MAX_VERTICES] = {0};
    for (size_t left = 0; left < n; ++left) {
        for (size_t right = left + 1; right < n; ++right) {
            if (!(adjacency[left] & (UINT32_C(1) << right)) ||
                (left == edge_u && right == edge_v)) continue;
            size_t new_left = left == edge_v ? edge_u : left;
            size_t new_right = right == edge_v ? edge_u : right;
            if (new_left > edge_v) --new_left;
            if (new_right > edge_v) --new_right;
            if (new_left == new_right) continue;
            contracted[new_left] |= UINT32_C(1) << new_right;
            contracted[new_right] |= UINT32_C(1) << new_left;
        }
    }
    int64_t with_edge_contracted[MAX_VERTICES + 1];
    chromatic_poly(contracted, n - 1, with_edge_contracted);
    for (size_t degree = 0; degree <= n; ++degree)
        result[degree] = without_edge[degree] - with_edge_contracted[degree];
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t chromatic_polynomial(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES ||
        length != 2 + 2 * (size_t)m_value) return -1;
    size_t n = (size_t)n_value, m = (size_t)m_value;
    uint32_t adjacency[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        int64_t u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value) return -1;
        size_t u = (size_t)u_value, v = (size_t)v_value;
        if (adjacency[u] & (UINT32_C(1) << v)) return -1;
        adjacency[u] |= UINT32_C(1) << v;
        adjacency[v] |= UINT32_C(1) << u;
    }
    size_t bytes = 8 * (n + 1);
    if (!output || capacity < bytes) return -2;
    int64_t coefficients[MAX_VERTICES + 1];
    chromatic_poly(adjacency, n, coefficients);
    for (size_t degree = 0; degree <= n; ++degree)
        write_i64_le(output, 8 * degree, coefficients[degree]);
    return (int64_t)bytes;
}
