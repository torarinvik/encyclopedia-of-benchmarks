#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t min_n = 3;
constexpr std::size_t max_n = 10;
constexpr std::size_t max_length = 37;

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_length) return -1;
    if (input[0] < static_cast<std::int64_t>(min_n)
            || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    std::size_t diagonal_count = 0;
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = i + 2; j < n; ++j) {
            if (!(i == 0 && j == n - 1)) ++diagonal_count;
        }
    }
    if (length != 1 + diagonal_count) return -1;

    std::array<std::array<std::int64_t, max_n>, max_n> weight{};
    std::size_t at = 1;
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = i + 2; j < n; ++j) {
            if (i == 0 && j == n - 1) continue;
            if (input[at] < 0 || input[at] > 1000) return -1;
            weight[i][j] = input[at++];
        }
    }

    std::array<std::array<std::int64_t, max_n>, max_n> dp{};
    for (std::size_t span = 2; span < n; ++span) {
        for (std::size_t left = 0; left + span < n; ++left) {
            const std::size_t right = left + span;
            std::int64_t best = std::numeric_limits<std::int64_t>::max();
            for (std::size_t split = left + 1; split < right; ++split) {
                const std::int64_t left_edge = split - left == 1 ? 0 : weight[left][split];
                const std::int64_t right_edge = right - split == 1 ? 0 : weight[split][right];
                const std::int64_t candidate = dp[left][split] + dp[split][right]
                                             + left_edge + right_edge;
                if (candidate < best) best = candidate;
            }
            dp[left][right] = best;
        }
    }
    return dp[0][n - 1];
}
} // namespace

extern "C" std::int64_t convex_polygon_minimum_weight_triangulation(
    const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
