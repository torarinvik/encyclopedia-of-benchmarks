/* Return the length of a strictly increasing subsequence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t longest_increasing_subsequence(const std::int64_t *values,
                                                        std::size_t length) noexcept
{
    if (length > 512 || (length != 0 && values == nullptr)) return -1;
    std::int64_t dp[512];
    std::int64_t longest = 0;
    for (std::size_t index = 0; index < length; ++index) {
        dp[index] = 1;
        for (std::size_t previous = 0; previous < index; ++previous) {
            if (values[index] > values[previous] && dp[index] < dp[previous] + 1)
                dp[index] = dp[previous] + 1;
        }
        if (dp[index] > longest) longest = dp[index];
    }
    return longest;
}
