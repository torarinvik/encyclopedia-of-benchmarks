#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8, max_m = 14, max_k = 5, max_input = 50, max_masks = 1 << max_k;
constexpr std::int64_t inf = INT64_C(1000000000000000000);
}

extern "C" std::int64_t steiner_tree_subset_dp(const std::int64_t* input, std::size_t length) noexcept {
    if (!input || length < 3 || length > max_input) return -1;
    const auto n0 = input[0], m0 = input[1], k0 = input[2];
    if (n0 < 1 || n0 > max_n || m0 < 0 || m0 > max_m || k0 < 1 || k0 > max_k || k0 > n0) return -1;
    const int n = static_cast<int>(n0), m = static_cast<int>(m0), k = static_cast<int>(k0);
    if (m > n * (n - 1) / 2 || length != static_cast<std::size_t>(3 + k + 3 * m)) return -1;

    std::array<bool, max_n> terminal_seen{};
    std::array<int, max_k> terminals{};
    for (int i = 0; i < k; ++i) {
        const auto vertex = input[3 + i];
        if (vertex < 0 || vertex >= n || terminal_seen[static_cast<std::size_t>(vertex)]) return -1;
        terminal_seen[static_cast<std::size_t>(vertex)] = true;
        terminals[static_cast<std::size_t>(i)] = static_cast<int>(vertex);
    }

    std::array<std::array<bool, max_n>, max_n> present{};
    std::array<std::array<std::int64_t, max_n>, max_n> weight{};
    for (int i = 0; i < m; ++i) {
        const auto u0 = input[3 + k + 3 * i], v0 = input[4 + k + 3 * i], w = input[5 + k + 3 * i];
        if (u0 < 0 || u0 >= v0 || v0 >= n || w < 0 || w > 1000) return -1;
        const int u = static_cast<int>(u0), v = static_cast<int>(v0);
        if (present[u][v]) return -1;
        present[u][v] = present[v][u] = true;
        weight[u][v] = weight[v][u] = w;
    }

    std::array<std::array<std::int64_t, max_n>, max_masks> dp{};
    for (auto& row : dp) row.fill(inf);
    for (int bit = 0; bit < k; ++bit) dp[1 << bit][terminals[bit]] = 0;
    const int masks = 1 << k;
    for (int mask = 1; mask < masks; ++mask) {
        if ((mask & (mask - 1)) != 0) {
            for (int sub = (mask - 1) & mask; sub != 0; sub = (sub - 1) & mask) {
                const int other = mask ^ sub;
                if (sub >= other) continue;
                for (int v = 0; v < n; ++v) if (dp[sub][v] < inf && dp[other][v] < inf) {
                    const auto candidate = dp[sub][v] + dp[other][v];
                    if (candidate < dp[mask][v]) dp[mask][v] = candidate;
                }
            }
        }
        std::array<bool, max_n> used{};
        for (int step = 0; step < n; ++step) {
            int chosen = -1;
            for (int v = 0; v < n; ++v)
                if (!used[v] && (chosen < 0 || dp[mask][v] < dp[mask][chosen])) chosen = v;
            if (chosen < 0 || dp[mask][chosen] >= inf) break;
            used[chosen] = true;
            for (int v = 0; v < n; ++v) if (present[chosen][v] && !used[v]) {
                const auto candidate = dp[mask][chosen] + weight[chosen][v];
                if (candidate < dp[mask][v]) dp[mask][v] = candidate;
            }
        }
    }
    std::int64_t answer = inf;
    for (int v = 0; v < n; ++v) if (dp[masks - 1][v] < answer) answer = dp[masks - 1][v];
    return answer >= inf ? -2 : answer;
}
