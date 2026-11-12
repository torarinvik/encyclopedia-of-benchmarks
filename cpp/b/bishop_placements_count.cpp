#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8, max_k = 16, max_diagonals = 2 * max_n;

int diagonal_size(int index) {
    return (index & 1) != 0 ? (index / 4) * 2 + 1 : ((index - 1) / 4) * 2 + 2;
}

std::array<std::int64_t, max_k + 1> color_counts(int k, int last_diagonal) {
    std::array<std::array<std::int64_t, max_k + 1>, max_diagonals> dp{};
    dp[0][0] = 1;
    dp[1][0] = 1;
    if (k >= 1) dp[1][1] = 1;
    for (int diagonal = 2; diagonal <= last_diagonal; ++diagonal) {
        dp[diagonal][0] = 1;
        const int squares = diagonal_size(diagonal);
        for (int placed = 1; placed <= k; ++placed)
            dp[diagonal][placed] = dp[diagonal - 2][placed] +
                dp[diagonal - 2][placed - 1] * (squares - placed + 1);
    }
    std::array<std::int64_t, max_k + 1> counts{};
    for (int placed = 0; placed <= k; ++placed) counts[placed] = dp[last_diagonal][placed];
    return counts;
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (!input || length != 2) return -1;
    if (input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_k) return -1;
    const int n = static_cast<int>(input[0]), k = static_cast<int>(input[1]);
    if (k > (n == 1 ? 1 : 2 * n - 2)) return 0;
    const auto black = color_counts(k, 2 * n - 1);
    const auto white = color_counts(k, 2 * n - 2);
    std::int64_t result = 0;
    for (int left = 0; left <= k; ++left) result += black[left] * white[k - left];
    return result;
}
}

extern "C" std::int64_t bishop_placements_count(const std::int64_t* input,
        std::size_t length) noexcept {
    return solve(input, length);
}
