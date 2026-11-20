// Exact minimum dominating set by closed-neighborhood branch and bound.
#include <cstddef>
#include <cstdint>
#include <algorithm>

namespace {
constexpr int MAX_N = 12;
constexpr std::size_t MAX_INPUT = 135;

int popcount_mask(std::uint16_t mask) {
    int count = 0;
    while (mask != 0) { mask = static_cast<std::uint16_t>(mask & (mask - 1)); ++count; }
    return count;
}

int search_mds(const std::uint16_t* closed, int n, std::uint16_t full,
               std::uint16_t covered, int chosen, int best) {
    if (chosen >= best) return best;
    if (covered == full) return chosen;
    const std::uint16_t uncovered = static_cast<std::uint16_t>(full & ~covered);
    const int uncovered_count = popcount_mask(uncovered);
    int maximum_gain = 0;
    for (int v = 0; v < n; ++v) maximum_gain = std::max(maximum_gain, popcount_mask(closed[v] & uncovered));
    const int lower_bound = (uncovered_count + maximum_gain - 1) / maximum_gain;
    if (chosen + lower_bound >= best) return best;

    int branch = -1, branch_degree = MAX_N + 1;
    for (int v = 0; v < n; ++v) if (uncovered & (std::uint16_t(1) << v)) {
        const int degree = popcount_mask(closed[v]);
        if (degree < branch_degree) { branch = v; branch_degree = degree; }
    }
    int candidates[MAX_N], gains[MAX_N], count = 0;
    for (int v = 0; v < n; ++v) if (closed[branch] & (std::uint16_t(1) << v)) {
        const int gain = popcount_mask(closed[v] & uncovered);
        int pos = count;
        while (pos > 0 && (gain > gains[pos - 1] || (gain == gains[pos - 1] && v < candidates[pos - 1]))) {
            gains[pos] = gains[pos - 1]; candidates[pos] = candidates[pos - 1]; --pos;
        }
        gains[pos] = gain; candidates[pos] = v; ++count;
    }
    for (int i = 0; i < count; ++i) {
        const int v = candidates[i];
        best = search_mds(closed, n, full, static_cast<std::uint16_t>(covered | closed[v]), chosen + 1, best);
    }
    return best;
}
} // namespace

extern "C" std::int64_t minimum_dominating_set_branch_bound(const std::int64_t* packed,
                                                               std::size_t length) noexcept {
    if (packed == nullptr || length < 2 || length > MAX_INPUT) return -1;
    const std::int64_t n64 = packed[0], m64 = packed[1];
    if (n64 < 1 || n64 > MAX_N) return -1;
    const int n = static_cast<int>(n64);
    const std::int64_t max_edges = n64 * (n64 - 1) / 2;
    if (m64 < 0 || m64 > max_edges || m64 > 66 || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    std::uint16_t adjacency[MAX_N]{};
    for (std::int64_t e = 0; e < m64; ++e) {
        const auto u64 = packed[2 + 2 * static_cast<std::size_t>(e)];
        const auto v64 = packed[3 + 2 * static_cast<std::size_t>(e)];
        if (u64 < 0 || v64 < 0 || u64 >= n64 || v64 >= n64 || u64 == v64) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        const auto bit = static_cast<std::uint16_t>(1u << v);
        if (adjacency[u] & bit) return -1;
        adjacency[u] = static_cast<std::uint16_t>(adjacency[u] | bit);
        adjacency[v] = static_cast<std::uint16_t>(adjacency[v] | (1u << u));
    }
    std::uint16_t closed[MAX_N]{};
    for (int v = 0; v < n; ++v) closed[v] = static_cast<std::uint16_t>(adjacency[v] | (1u << v));
    const auto full = static_cast<std::uint16_t>((1u << n) - 1u);
    std::uint16_t covered = 0;
    int greedy = 0;
    while (covered != full) {
        int chosen_vertex = 0, best_gain = -1;
        for (int v = 0; v < n; ++v) {
            const int gain = popcount_mask(closed[v] & static_cast<std::uint16_t>(~covered));
            if (gain > best_gain) { best_gain = gain; chosen_vertex = v; }
        }
        covered = static_cast<std::uint16_t>(covered | closed[chosen_vertex]); ++greedy;
    }
    return search_mds(closed, n, full, 0, 0, greedy);
}
