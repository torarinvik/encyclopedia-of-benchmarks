#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 16;
int find_root(std::array<int, kMaxN>& parent, int node) noexcept {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}
}

extern "C" std::int64_t redundant_directed_connection_repair(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 34) return -1;
    const auto n_value = input[0];
    if (n_value < 3 || n_value > 16) return -1;
    const int n = static_cast<int>(n_value);
    if (length != static_cast<std::size_t>(1 + 2 * n)) return -1;
    std::array<int, kMaxN> from{}, to{}, incoming{}, parent{}, size{};
    incoming.fill(-1);
    for (int node = 0; node < n; ++node) { parent[node] = node; size[node] = 1; }
    for (int edge = 0; edge < n; ++edge) {
        const auto u = input[1 + 2 * edge], v = input[2 + 2 * edge];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v) return -1;
        from[edge] = static_cast<int>(u);
        to[edge] = static_cast<int>(v);
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
        int a = find_root(parent, from[edge]);
        int b = find_root(parent, to[edge]);
        if (a == b) { cycle_edge = edge; break; }
        if (size[a] < size[b]) { const int swap = a; a = b; b = swap; }
        parent[b] = a;
        size[a] += size[b];
    }
    if (cycle_edge >= 0) return second_parent >= 0 ? first_parent : cycle_edge;
    return second_parent;
}
