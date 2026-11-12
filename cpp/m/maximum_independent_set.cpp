// Exact MIS by maximum-degree branching and a greedy clique-cover bound.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 22;
constexpr std::size_t MAX_INPUT = 465;

struct MisSearch {
    std::uint64_t adjacency[MAX_N]{};
    int best = 0;
};

int popcount64(std::uint64_t bits) {
    int count = 0;
    while (bits != 0) { bits &= bits - 1; ++count; }
    return count;
}

int first_vertex(std::uint64_t bits) {
    int vertex = 0;
    while ((bits & UINT64_C(1)) == 0) { bits >>= 1; ++vertex; }
    return vertex;
}

int clique_cover_bound(const MisSearch& search, std::uint64_t remaining) {
    int cliques = 0;
    while (remaining != 0) {
        ++cliques;
        std::uint64_t candidates = remaining;
        while (candidates != 0) {
            const std::uint64_t bit = candidates & (~candidates + UINT64_C(1));
            const int vertex = first_vertex(bit);
            remaining &= ~bit;
            candidates &= ~bit;
            candidates &= search.adjacency[vertex];
        }
    }
    return cliques;
}

void search_mis(MisSearch& search, std::uint64_t remaining, int chosen) {
    if (remaining == 0) { if (chosen > search.best) search.best = chosen; return; }
    if (chosen + popcount64(remaining) <= search.best) return;
    if (chosen + clique_cover_bound(search, remaining) <= search.best) return;
    int branch = -1, branch_degree = -1;
    for (std::uint64_t vertices = remaining; vertices != 0;) {
        const std::uint64_t bit = vertices & (~vertices + UINT64_C(1));
        const int vertex = first_vertex(bit);
        const int degree = popcount64(search.adjacency[vertex] & remaining);
        if (degree > branch_degree) { branch = vertex; branch_degree = degree; }
        vertices &= ~bit;
    }
    const std::uint64_t bit = UINT64_C(1) << branch;
    search_mis(search, remaining & ~bit & ~search.adjacency[branch], chosen + 1);
    search_mis(search, remaining & ~bit, chosen);
}
} // namespace

extern "C" std::int64_t maximum_independent_set(const std::int64_t* packed,
                                                  std::size_t length) noexcept {
    if (packed == nullptr || length < 2 || length > MAX_INPUT) return -1;
    const std::int64_t n64 = packed[0], m64 = packed[1];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::int64_t max_edges = n64 * (n64 - 1) / 2;
    if (m64 < 0 || m64 > max_edges || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    MisSearch search;
    for (std::int64_t edge = 0; edge < m64; ++edge) {
        const std::int64_t u64 = packed[2 + 2 * static_cast<std::size_t>(edge)];
        const std::int64_t v64 = packed[3 + 2 * static_cast<std::size_t>(edge)];
        if (u64 < 0 || v64 < 0 || u64 >= n64 || v64 >= n64 || u64 == v64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        const std::uint64_t bit = UINT64_C(1) << v;
        if (search.adjacency[u] & bit) return -1;
        search.adjacency[u] |= bit;
        search.adjacency[v] |= UINT64_C(1) << u;
    }
    search_mis(search, (UINT64_C(1) << n) - UINT64_C(1), 0);
    return search.best;
}
