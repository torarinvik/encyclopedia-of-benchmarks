#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t minimum_cost_path(const std::int64_t *values, std::size_t length) noexcept {
    constexpr std::int64_t invalid = std::numeric_limits<std::int64_t>::min();
    if (values == nullptr || length < 3) return invalid;
    const auto rv = values[0], cv = values[1];
    if (rv < 1 || rv > 16 || cv < 1 || cv > 16) return invalid;
    const auto rows = static_cast<std::size_t>(rv), cols = static_cast<std::size_t>(cv);
    if (length != 2 + rows * cols) return invalid;
    std::int64_t dp[16][16];
    for (std::size_t r = 0; r < rows; ++r) for (std::size_t c = 0; c < cols; ++c) {
        const auto x = values[2 + r * cols + c];
        if (x < INT32_MIN || x > INT32_MAX) return invalid;
        dp[r][c] = x;
    }
    for (std::size_t c = 1; c < cols; ++c) dp[0][c] += dp[0][c - 1];
    for (std::size_t r = 1; r < rows; ++r) dp[r][0] += dp[r - 1][0];
    for (std::size_t r = 1; r < rows; ++r) for (std::size_t c = 1; c < cols; ++c)
        dp[r][c] += dp[r - 1][c] < dp[r][c - 1] ? dp[r - 1][c] : dp[r][c - 1];
    return dp[rows - 1][cols - 1];
}
