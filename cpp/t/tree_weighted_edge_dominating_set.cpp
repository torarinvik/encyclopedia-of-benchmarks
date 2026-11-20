// Uncompiled minimum-weight tree edge-domination draft.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tree_weighted_edge_dominating_set(const std::int64_t* input, std::size_t length) {
    constexpr std::int64_t inf = 1000000000000LL;
    if (!input || length < 1 || length > 128) return -1;
    const auto nv = input[0];
    if (nv < 1 || nv > 64 || length != static_cast<std::size_t>(2 * nv - 1)) return -1;
    const auto n = static_cast<std::size_t>(nv);
    for (std::size_t v = 1; v < n; ++v)
        if (input[v] < 0 || input[v] >= static_cast<std::int64_t>(v) ||
            input[n + v - 1] < 0 || input[n + v - 1] > 1000000) return -1;
    std::array<std::int64_t, 64> selected, closed{}, pending{};
    selected.fill(inf);
    for (std::size_t v = n; v-- > 1;) {
        const auto p = static_cast<std::size_t>(input[v]);
        const auto skip = std::min(selected[v], closed[v]);
        const auto take = input[n + v - 1] + std::min(selected[v], pending[v]);
        selected[p] = std::min({inf, selected[p] + std::min(skip, take), pending[p] + take});
        closed[p] = std::min(inf, closed[p] + selected[v]);
        pending[p] = std::min(inf, pending[p] + skip);
    }
    return std::min(selected[0], closed[0]);
}
