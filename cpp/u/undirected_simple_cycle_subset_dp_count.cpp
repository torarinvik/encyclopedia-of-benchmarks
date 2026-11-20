// Clean-room all-length simple-cycle subset DP; see package RIGHTS.md.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t undirected_simple_cycle_subset_dp_count(
    const std::int64_t* input, std::size_t length) noexcept {
    constexpr std::size_t MaxN = 14;
    constexpr std::size_t MaxM = 91;
    constexpr std::size_t MaxStates = 1u << MaxN;
    if (!input || length < 2 || length > 185) return -1;
    const auto n64 = input[0];
    const auto m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) || m64 > n64 * (n64 - 1) / 2) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto m = static_cast<std::size_t>(m64);
    if (length != 2 + 2 * m) return -1;

    std::array<std::array<std::uint8_t, MaxN>, MaxN> adjacency{};
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
        adjacency[u][v] = adjacency[v][u] = 1;
        neighbors[u][degree[u]++] = v;
        neighbors[v][degree[v]++] = u;
    }

    std::array<std::array<std::int64_t, MaxN>, MaxStates> dp{};
    const auto state_count = std::size_t{1} << n;
    for (std::size_t start = 0; start < n; ++start) dp[std::size_t{1} << start][start] = 1;
    std::int64_t oriented_cycles = 0;
    for (std::size_t mask = 1; mask < state_count; ++mask) {
        std::size_t start = 0;
        while ((mask & (std::size_t{1} << start)) == 0) ++start;
        std::size_t cardinality = 0;
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            if (mask & (std::size_t{1} << vertex)) ++cardinality;
        for (std::size_t endpoint = 0; endpoint < n; ++endpoint) {
            if ((mask & (std::size_t{1} << endpoint)) == 0) continue;
            const auto ways = dp[mask][endpoint];
            if (ways == 0) continue;
            if (cardinality >= 3 && adjacency[endpoint][start]) oriented_cycles += ways;
            for (std::size_t i = 0; i < degree[endpoint]; ++i) {
                const auto next = neighbors[endpoint][i];
                if (next > start && (mask & (std::size_t{1} << next)) == 0)
                    dp[mask | (std::size_t{1} << next)][next] += ways;
            }
        }
    }
    return oriented_cycles / 2;
}
