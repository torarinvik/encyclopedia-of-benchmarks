/* Return the longest palindromic subsequence length using interval DP. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 128;
}

extern "C" std::int64_t longest_palindromic_subsequence(const std::int64_t *values,
                                                        std::size_t length) noexcept
{
    if (length > max_values) return -1;
    if (length == 0) return 0;
    std::int64_t dp[max_values] = {};
    for (std::size_t start = length; start > 0;) {
        --start;
        dp[start] = 1;
        std::int64_t diagonal = 0;
        for (std::size_t end = start + 1; end < length; ++end) {
            const std::int64_t previous = dp[end];
            if (values[start] == values[end]) {
                dp[end] = diagonal + 2;
            } else {
                dp[end] = dp[end] > dp[end - 1] ? dp[end] : dp[end - 1];
            }
            diagonal = previous;
        }
    }
    return dp[length - 1];
}
