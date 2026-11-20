// Independently authored bounded subset-assignment draft; unverified.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t tree_sibling_distinct_cost_coloring(const int64_t* input, std::size_t length) {
    if (!input || length < 3 || length > 354) return -1;
    if (input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > 10) return -1;
    const int n = static_cast<int>(input[0]), k = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(n + 1 + n * k)) return -1;
    for (int v = 1; v < n; ++v)
        if (input[1 + v] < 0 || input[1 + v] >= v) return -1;
    for (int i = 0; i < n * k; ++i)
        if (input[n + 1 + i] < 0 || input[n + 1 + i] > 1000000) return -1;
    constexpr int64_t inf = 1000000000000LL;
    std::array<std::array<int64_t, 10>, 32> dp{};
    std::array<int64_t, 1024> current{}, next{};
    const int states = 1 << k;
    for (int v = n - 1; v >= 0; --v) {
        for (int color = 0; color < k; ++color) {
            std::fill_n(current.begin(), states, inf);
            current[1 << color] = 0;
            for (int child = v + 1; child < n; ++child) {
                if (input[1 + child] != v) continue;
                std::fill_n(next.begin(), states, inf);
                for (int mask = 0; mask < states; ++mask) {
                    if (current[mask] == inf) continue;
                    for (int c = 0; c < k; ++c) {
                        if ((mask & (1 << c)) || dp[child][c] == inf) continue;
                        const int extended = mask | (1 << c);
                        next[extended] = std::min(next[extended], current[mask] + dp[child][c]);
                    }
                }
                std::copy_n(next.begin(), states, current.begin());
            }
            const auto best = *std::min_element(current.begin(), current.begin() + states);
            dp[v][color] = best == inf ? inf : best + input[n + 1 + v * k + color];
        }
    }
    const auto best = *std::min_element(dp[0].begin(), dp[0].begin() + k);
    return best == inf ? -2 : best;
}
