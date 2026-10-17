#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 64
#define MAX_INPUT_LENGTH 129

static size_t find_root(size_t *parent, size_t vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

int64_t lca(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n64 = input[0];
    if (n64 < 1 || n64 > MAX_NODES) return -1;
    const size_t n = (size_t)n64;
    if (length != 2 * n + 1) return -1;

    size_t dsu[MAX_NODES], degree[MAX_NODES] = {0};
    size_t adjacency[MAX_NODES][MAX_NODES];
    for (size_t i = 0; i < n; ++i) dsu[i] = i;
    size_t position = 1;
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const int64_t u64 = input[position], v64 = input[position + 1];
        position += 2;
        if (u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 == v64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        const size_t ru = find_root(dsu, u), rv = find_root(dsu, v);
        if (ru == rv) return -1;
        dsu[ru] = rv;
        adjacency[u][degree[u]++] = v;
        adjacency[v][degree[v]++] = u;
    }
    const int64_t query_a64 = input[position], query_b64 = input[position + 1];
    if (query_a64 < 0 || query_a64 >= n64 || query_b64 < 0 || query_b64 >= n64) return -1;
    const size_t component = find_root(dsu, 0);
    for (size_t vertex = 1; vertex < n; ++vertex)
        if (find_root(dsu, vertex) != component) return -1;

    size_t parent[MAX_NODES], depth[MAX_NODES], stack[MAX_NODES];
    uint8_t seen[MAX_NODES] = {0};
    size_t stack_size = 0;
    parent[0] = 0; depth[0] = 0; seen[0] = 1;
    stack[stack_size++] = 0;
    while (stack_size > 0) {
        const size_t vertex = stack[--stack_size];
        for (size_t i = 0; i < degree[vertex]; ++i) {
            const size_t next = adjacency[vertex][i];
            if (!seen[next]) {
                seen[next] = 1;
                parent[next] = vertex;
                depth[next] = depth[vertex] + 1;
                stack[stack_size++] = next;
            }
        }
    }

    size_t a = (size_t)query_a64, b = (size_t)query_b64;
    if (depth[a] < depth[b]) { const size_t t = a; a = b; b = t; }
    while (depth[a] != depth[b]) a = parent[a];
    if (a == b) return (int64_t)a;
    while (a != b) { a = parent[a]; b = parent[b]; }
    return (int64_t)a;
}
