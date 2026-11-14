#include <stddef.h>
#include <stdint.h>

int64_t xor_leaf_tree_traversal(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (!input || length < 2 || input[0] < 1 || input[0] > 64) return -1;
    const int n = (int)input[0];
    if (input[1] < 0 || input[1] >= n || length != (size_t)(2 * n)) return -1;
    const int root = (int)input[1];
    int degree[64] = {0}, edge_xor[64] = {0}, endpoints_a[63], endpoints_b[63];
    int dsu[64], ranks[64] = {0}, parent_edge[64], order[64];
    for (int i = 0; i < n; ++i) { dsu[i] = i; parent_edge[i] = -1; }
    for (int e = 0; e < n - 1; ++e) {
        int64_t a = input[2 + 2 * e], b = input[3 + 2 * e];
        if (a < 0 || a >= n || b < 0 || b >= n || a == b) return -1;
        int ra = (int)a, rb = (int)b;
        while (dsu[ra] != ra) { dsu[ra] = dsu[dsu[ra]]; ra = dsu[ra]; }
        while (dsu[rb] != rb) { dsu[rb] = dsu[dsu[rb]]; rb = dsu[rb]; }
        if (ra == rb) return -1;
        if (ranks[ra] < ranks[rb]) dsu[ra] = rb;
        else {
            dsu[rb] = ra;
            if (ranks[ra] == ranks[rb]) ++ranks[ra];
        }
        endpoints_a[e] = (int)a; endpoints_b[e] = (int)b;
        ++degree[a]; ++degree[b]; edge_xor[a] ^= e; edge_xor[b] ^= e;
    }
    degree[root] = 0;
    int used = 0;
    for (int start = 0; start < n; ++start) {
        int v = start;
        while (degree[v] == 1) {
            int e = edge_xor[v];
            int next = endpoints_a[e] ^ endpoints_b[e] ^ v;
            parent_edge[v] = e; order[used++] = v; degree[v] = 0;
            --degree[next]; edge_xor[next] ^= e; v = next;
        }
    }
    order[used++] = root;
    if (used != n) return -1;
    const size_t required = (size_t)n * 16;
    if (!output || capacity < required) return -2;
    for (int i = 0; i < 2 * n; ++i) {
        uint64_t word = (uint64_t)(int64_t)(i < n ? parent_edge[i] : order[i - n]);
        for (int b = 0; b < 8; ++b) output[8 * i + b] = (uint8_t)(word >> (8 * b));
    }
    return (int64_t)required;
}
