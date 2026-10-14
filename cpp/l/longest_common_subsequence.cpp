/* Return the LCS length of two packed ASCII sequences. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t longest_common_subsequence(const std::int64_t *packed,
                                                     std::size_t length) noexcept
{
    if (packed == nullptr || length < 2 || length > 512) return -1;
    const std::int64_t left_length = packed[0];
    const std::int64_t right_length = packed[1];
    if (left_length < 0 || left_length > 255 || right_length < 0 || right_length > 255 ||
        length != static_cast<std::size_t>(2 + left_length + right_length)) return -1;
    for (std::size_t index = 0; index < static_cast<std::size_t>(left_length + right_length); ++index) {
        if (packed[2 + index] < 0 || packed[2 + index] > 127) return -1;
    }

    std::int64_t dp[256]{};
    for (std::size_t left = 0; left < static_cast<std::size_t>(left_length); ++left) {
        std::int64_t diagonal = 0;
        for (std::size_t right = 1; right <= static_cast<std::size_t>(right_length); ++right) {
            const std::int64_t above = dp[right];
            if (packed[2 + left] == packed[2 + static_cast<std::size_t>(left_length) + right - 1]) {
                dp[right] = diagonal + 1;
            } else if (dp[right - 1] > dp[right]) {
                dp[right] = dp[right - 1];
            }
            diagonal = above;
        }
    }
    return dp[static_cast<std::size_t>(right_length)];
}
