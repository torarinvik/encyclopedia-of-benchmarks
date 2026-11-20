#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_PARSEABLE_LENGTH = 34 };

static int repair_find(int parent[MAX_N], int node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

int64_t redundant_directed_connection_repair(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 3 || n_value > MAX_N) return -1;
    const int n = (int)n_value;
    if (length != (size_t)(1 + 2 * n)) return -1;
    int from[MAX_N], to[MAX_N], incoming[MAX_N], parent[MAX_N], size[MAX_N];
    for (int node = 0; node < n; ++node) { incoming[node] = -1; parent[node] = node; size[node] = 1; }
    for (int edge = 0; edge < n; ++edge) {
        const int64_t u = input[1 + 2 * edge], v = input[2 + 2 * edge];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v) return -1;
        from[edge] = (int)u;
        to[edge] = (int)v;
        for (int prior = 0; prior < edge; ++prior)
            if (from[prior] == u && to[prior] == v) return -1;
    }
    int first_parent = -1, second_parent = -1;
    for (int edge = 0; edge < n; ++edge) {
        const int child = to[edge];
        if (incoming[child] < 0) incoming[child] = edge;
        else { first_parent = incoming[child]; second_parent = edge; break; }
    }
    int cycle_edge = -1;
    for (int edge = 0; edge < n; ++edge) {
        if (edge == second_parent) continue;
        int a = repair_find(parent, from[edge]);
        int b = repair_find(parent, to[edge]);
        if (a == b) { cycle_edge = edge; break; }
        if (size[a] < size[b]) { int swap = a; a = b; b = swap; }
        parent[b] = a;
        size[a] += size[b];
    }
    if (cycle_edge >= 0) return second_parent >= 0 ? first_parent : cycle_edge;
    return second_parent;
}
