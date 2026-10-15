/* Count unordered partitions of a positive integer using the pinned 2D DP. */
#include <cstdint>

extern "C" std::int64_t integer_partition(std::int64_t m) noexcept
{
    constexpr std::int64_t max_n = 300;
    constexpr std::int64_t stride = 300;
    if (m < 1 || m > max_n) return INT64_MIN;

    std::int64_t memo[(max_n + 1) * stride] = {};
    for (std::int64_t i = 0; i <= m; ++i) memo[i * stride] = 1;
    for (std::int64_t n = 0; n <= m; ++n) {
        for (std::int64_t k = 1; k < m; ++k) {
            memo[n * stride + k] += memo[n * stride + k - 1];
            if (n - k > 0) memo[(n * stride) + k] += memo[(n - k - 1) * stride + k];
        }
    }
    return memo[m * stride + m - 1];
}
