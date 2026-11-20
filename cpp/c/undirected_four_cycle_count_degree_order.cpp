// Clean-room degree-oriented simple C4 counter; see package RIGHTS.md.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t undirected_four_cycle_count_degree_order(
    const std::int64_t* input, std::size_t length) noexcept {
    constexpr std::size_t MaxN = 16;
    constexpr std::size_t MaxM = 64;
    if (!input || length < 2 || length > 131) return -1;
    const auto n64 = input[0];
    const auto m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto m = static_cast<std::size_t>(m64);
    if (length != 2 + 2 * m) return -1;

    std::array<std::array<std::size_t, MaxN>, MaxN> neighbors{};
    std::array<std::size_t, MaxN> degree{};
    std::int64_t previous_u = -1;
    std::int64_t previous_v = -1;
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge];
        const auto v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 >= v64) return -1;
        if (edge != 0 && (u64 < previous_u || (u64 == previous_u && v64 <= previous_v))) return -1;
        previous_u = u64;
        previous_v = v64;
        const auto u = static_cast<std::size_t>(u64);
        const auto v = static_cast<std::size_t>(v64);
        neighbors[u][degree[u]++] = v;
        neighbors[v][degree[v]++] = u;
    }

    std::array<std::size_t, MaxN> order{};
    std::array<std::size_t, MaxN> rank{};
    for (std::size_t i = 0; i < n; ++i) order[i] = i;
    for (std::size_t i = 1; i < n; ++i) {
        const auto key = order[i];
        auto j = i;
        while (j > 0) {
            const auto prior = order[j - 1];
            if (degree[prior] < degree[key] ||
                (degree[prior] == degree[key] && prior < key)) break;
            order[j] = prior;
            --j;
        }
        order[j] = key;
    }
    for (std::size_t i = 0; i < n; ++i) rank[order[i]] = i;

    std::array<std::int64_t, MaxN> count{};
    std::int64_t total = 0;
    for (std::size_t position = 0; position < n; ++position) {
        const auto pivot = order[position];
        for (std::size_t bi = 0; bi < degree[pivot]; ++bi) {
            const auto middle = neighbors[pivot][bi];
            if (rank[middle] >= position) continue;
            for (std::size_t ci = 0; ci < degree[middle]; ++ci) {
                const auto opposite = neighbors[middle][ci];
                if (rank[opposite] < position) {
                    total += count[opposite];
                    ++count[opposite];
                }
            }
        }
        for (std::size_t vertex = 0; vertex < n; ++vertex) count[vertex] = 0;
    }
    return total;
}
