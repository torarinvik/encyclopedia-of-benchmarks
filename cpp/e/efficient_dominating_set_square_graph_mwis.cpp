// Efficient domination through weighted independent set on the square graph.
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 12;
int bit_count(std::uint16_t bits) {
    int count = 0;
    while (bits != 0) { bits = static_cast<std::uint16_t>(bits & (bits - 1)); ++count; }
    return count;
}

struct Search {
    std::uint16_t square[kMaxVertices]{};
    int weight[kMaxVertices]{};
    int best = 0;
};

void weighted_mis(Search& search, std::uint16_t remaining, int current) {
    int upper = current;
    for (int v = 0; v < kMaxVertices; ++v)
        if ((remaining & (std::uint16_t(1) << v)) != 0) upper += search.weight[v];
    if (upper <= search.best) return;
    if (remaining == 0) { search.best = current; return; }

    int branch = -1, branch_degree = -1;
    for (int v = 0; v < kMaxVertices; ++v) {
        if ((remaining & (std::uint16_t(1) << v)) == 0) continue;
        const int degree = bit_count(static_cast<std::uint16_t>(search.square[v] & remaining));
        if (degree > branch_degree) { branch = v; branch_degree = degree; }
    }
    const std::uint16_t bit = std::uint16_t(1) << branch;
    weighted_mis(search, static_cast<std::uint16_t>(remaining & ~bit & ~search.square[branch]),
                 current + search.weight[branch]);
    weighted_mis(search, static_cast<std::uint16_t>(remaining & ~bit), current);
}
} // namespace

extern "C" std::int64_t efficient_dominating_set_square_graph_mwis(const std::int64_t* input,
                                                                      std::size_t length) {
    if (input == nullptr || length < 2 || length > 135) return -1;
    const std::int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > kMaxVertices) return -1;
    const std::int64_t max_edges = n64 * (n64 - 1) / 2;
    if (m64 < 0 || m64 > max_edges || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;

    const int n = static_cast<int>(n64);
    std::uint16_t adjacency[kMaxVertices]{};
    for (std::int64_t e = 0; e < m64; ++e) {
        const std::int64_t u64 = input[2 + 2 * static_cast<std::size_t>(e)];
        const std::int64_t v64 = input[3 + 2 * static_cast<std::size_t>(e)];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        const std::uint16_t vbit = std::uint16_t(1) << v;
        if ((adjacency[u] & vbit) != 0) return -1;
        adjacency[u] = static_cast<std::uint16_t>(adjacency[u] | vbit);
        adjacency[v] = static_cast<std::uint16_t>(adjacency[v] | (std::uint16_t(1) << u));
    }

    Search search{};
    for (int v = 0; v < n; ++v) {
        search.square[v] = adjacency[v];
        for (int u = 0; u < n; ++u)
            if ((adjacency[v] & (std::uint16_t(1) << u)) != 0)
                search.square[v] = static_cast<std::uint16_t>(search.square[v] | adjacency[u]);
        search.square[v] = static_cast<std::uint16_t>(search.square[v] & ~(std::uint16_t(1) << v));
        search.weight[v] = bit_count(adjacency[v]) + 1;
    }
    const std::uint16_t all = static_cast<std::uint16_t>((std::uint16_t(1) << n) - 1);
    weighted_mis(search, all, 0);
    return search.best == n ? 1 : 0;
}
