#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 256
#define MAX_EDGES 512

static void visit(size_t vertex, size_t n, const uint8_t *adj, uint8_t *seen) {
    seen[vertex] = 1;
    for (size_t next = 0; next < n; ++next) {
        if (adj[vertex * MAX_VERTICES + next] && !seen[next]) visit(next, n, adj, seen);
    }
}

int64_t connected_components(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;
    uint8_t adjacency[MAX_VERTICES * MAX_VERTICES] = {0};
    for (size_t i = 0; i < m; ++i) {
        int64_t u = input[2 + 2 * i], v = input[3 + 2 * i];
        if (u < 1 || u > (int64_t)n || v < 1 || v > (int64_t)n) return -1;
        size_t a = (size_t)u - 1, b = (size_t)v - 1;
        adjacency[a * MAX_VERTICES + b] = adjacency[b * MAX_VERTICES + a] = 1;
    }
    uint8_t seen[MAX_VERTICES] = {0};
    int64_t components = 0;
    for (size_t i = 0; i < n; ++i) if (!seen[i]) { visit(i, n, adjacency, seen); ++components; }
    return components;
}
