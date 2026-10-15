/* Bottom-up count of ordered denomination sequences. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t combination_sum_iv(const std::int64_t *packed, std::size_t length) noexcept
{
    constexpr std::int64_t invalid = INT64_MIN;
    if (packed == nullptr || length < 2 || length > 18) return invalid;
    if (packed[0] < 0 || packed[0] > 16 || packed[1] < 0 || packed[1] > 63) return invalid;
    const auto count = static_cast<std::size_t>(packed[0]);
    const auto target = static_cast<std::size_t>(packed[1]);
    if (length != count + 2) return invalid;
    for (std::size_t i = 0; i < count; ++i) {
        if (packed[i + 2] < 1 || packed[i + 2] > 63) return invalid;
        for (std::size_t j = 0; j < i; ++j) {
            if (packed[i + 2] == packed[j + 2]) return invalid;
        }
    }

    std::int64_t dp[64] = {};
    dp[0] = 1;
    for (std::size_t sum = 1; sum <= target; ++sum) {
        for (std::size_t i = 0; i < count; ++i) {
            const auto denomination = static_cast<std::size_t>(packed[i + 2]);
            if (denomination <= sum) dp[sum] += dp[sum - denomination];
        }
    }
    return dp[target];
}
