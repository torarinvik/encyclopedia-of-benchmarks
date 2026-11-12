#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t knuth_optimized_optimal_binary_search_tree(const std::int64_t *v, std::size_t n) {
    if (v == nullptr || n < 2 || n > 65 || v[0] < 1 || v[0] > 64 || n != static_cast<std::size_t>(v[0]) + 1) return -1;
    const auto k = static_cast<std::size_t>(v[0]);
    std::array<std::int64_t, 65> prefix{};
    std::array<std::array<std::int64_t, 64>, 64> dp{};
    std::array<std::array<std::size_t, 64>, 64> opt{};
    for (std::size_t i = 0; i < k; ++i) {
        const auto f = v[i + 1]; if (f < 0 || f > 1'000'000) return -1;
        prefix[i + 1] = prefix[i] + f; dp[i][i] = f; opt[i][i] = i;
    }
    for (std::size_t width = 2; width <= k; ++width) {
        for (std::size_t left = 0; left + width <= k; ++left) {
            const auto right = left + width - 1;
            const auto first = opt[left][right - 1], last = opt[left + 1][right];
            auto best = std::numeric_limits<std::int64_t>::max(); auto best_root = first;
            const auto total = prefix[right + 1] - prefix[left];
            for (auto root = first; root <= last; ++root) {
                auto cost = total;
                if (root > left) cost += dp[left][root - 1];
                if (root < right) cost += dp[root + 1][right];
                if (cost < best) { best = cost; best_root = root; }
            }
            dp[left][right] = best; opt[left][right] = best_root;
        }
    }
    return dp[0][k - 1];
}
