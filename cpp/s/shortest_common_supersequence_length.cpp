/* Return shortest common supersequence length for two packed ASCII sequences. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t shortest_common_supersequence_length(const std::int64_t *packed,
                                                               std::size_t length) noexcept
{
    if (packed == nullptr || length < 2 || length > 512) return -1;
    const std::int64_t m = packed[0], n = packed[1];
    if (m < 0 || m > 255 || n < 0 || n > 255 ||
        length != static_cast<std::size_t>(2 + m + n)) return -1;
    for (std::size_t k = 0; k < static_cast<std::size_t>(m + n); ++k)
        if (packed[2 + k] < 0 || packed[2 + k] > 127) return -1;

    const std::size_t columns = static_cast<std::size_t>(n) + 1;
    std::int64_t dp[256 * 256]{};
    for (std::size_t i = 1; i <= static_cast<std::size_t>(m); ++i) {
        for (std::size_t j = 1; j <= static_cast<std::size_t>(n); ++j) {
            const std::size_t cell = i * columns + j;
            if (packed[1 + i] == packed[1 + static_cast<std::size_t>(m) + j])
                dp[cell] = dp[(i - 1) * columns + j - 1] + 1;
            else {
                const auto above = dp[(i - 1) * columns + j];
                const auto left = dp[i * columns + j - 1];
                dp[cell] = above > left ? above : left;
            }
        }
    }
    return m + n - dp[static_cast<std::size_t>(m) * columns + static_cast<std::size_t>(n)];
}
