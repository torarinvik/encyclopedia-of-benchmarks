#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t xor_leaf_tree_traversal(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (!input || length < 2 || input[0] < 1 || input[0] > 64) return -1;
    const int n = static_cast<int>(input[0]);
    if (input[1] < 0 || input[1] >= n || length != static_cast<size_t>(2 * n)) return -1;
    const int root = static_cast<int>(input[1]);
    std::array<int, 64> degree{}, edge_xor{}, dsu{}, rank{}, parents{}, order{};
    std::array<int, 63> a{}, b{};
    for (int i = 0; i < n; ++i) { dsu[i] = i; parents[i] = -1; }
    for (int e = 0; e < n - 1; ++e) {
        const auto u = input[2 + 2 * e], v = input[3 + 2 * e];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v) return -1;
        int x = static_cast<int>(u), y = static_cast<int>(v);
        while (dsu[x] != x) { dsu[x] = dsu[dsu[x]]; x = dsu[x]; }
        while (dsu[y] != y) { dsu[y] = dsu[dsu[y]]; y = dsu[y]; }
        if (x == y) return -1;
        if (rank[x] < rank[y]) dsu[x] = y;
        else { dsu[y] = x; if (rank[x] == rank[y]) ++rank[x]; }
        a[e] = static_cast<int>(u); b[e] = static_cast<int>(v);
        ++degree[u]; ++degree[v]; edge_xor[u] ^= e; edge_xor[v] ^= e;
    }
    degree[root] = 0;
    int used = 0;
    for (int start = 0; start < n; ++start) {
        int v = start;
        while (degree[v] == 1) {
            const int edge = edge_xor[v];
            const int next = a[edge] ^ b[edge] ^ v;
            parents[v] = edge; order[used++] = v; degree[v] = 0;
            --degree[next]; edge_xor[next] ^= edge; v = next;
        }
    }
    order[used++] = root;
    if (used != n) return -1;
    const size_t required = static_cast<size_t>(16 * n);
    if (!output || capacity < required) return -2;
    for (int i = 0; i < 2 * n; ++i) {
        auto word = static_cast<uint64_t>(static_cast<int64_t>(i < n ? parents[i] : order[i - n]));
        for (int j = 0; j < 8; ++j) output[8 * i + j] = static_cast<uint8_t>(word >> (8 * j));
    }
    return static_cast<int64_t>(required);
}
