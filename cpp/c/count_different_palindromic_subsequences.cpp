#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxLength = 20;
constexpr std::int64_t kModulus = 1'000'000'007;
std::int64_t normalize(std::int64_t value) noexcept {
    value %= kModulus;
    return value < 0 ? value + kModulus : value;
}
}

extern "C" std::int64_t count_different_palindromic_subsequences(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > kMaxLength + 2) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxLength)
        || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    std::array<int, kMaxLength> symbols{};
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 0 || input[i + 1] > 3) return -1;
        symbols[i] = static_cast<int>(input[i + 1]);
    }
    if (n == 0) return 0;
    std::array<int, kMaxLength> next_equal{}, previous_equal{};
    std::array<int, 4> next_at{}; next_at.fill(static_cast<int>(n));
    std::array<int, 4> previous_at{}; previous_at.fill(-1);
    for (std::size_t i = n; i > 0;) {
        --i; next_equal[i] = next_at[static_cast<std::size_t>(symbols[i])];
        next_at[static_cast<std::size_t>(symbols[i])] = static_cast<int>(i);
    }
    for (std::size_t i = 0; i < n; ++i) {
        previous_equal[i] = previous_at[static_cast<std::size_t>(symbols[i])];
        previous_at[static_cast<std::size_t>(symbols[i])] = static_cast<int>(i);
    }
    std::array<std::array<std::int64_t, kMaxLength>, kMaxLength> dp{};
    for (std::size_t i = 0; i < n; ++i) dp[i][i] = 1;
    for (std::size_t width = 2; width <= n; ++width) {
        for (std::size_t left = 0; left + width <= n; ++left) {
            const auto right = left + width - 1;
            const auto inner = width > 2 ? dp[left + 1][right - 1] : 0;
            if (symbols[left] != symbols[right]) {
                dp[left][right] = normalize(dp[left + 1][right] + dp[left][right - 1] - inner);
                continue;
            }
            const int first = next_equal[left], last = previous_equal[right];
            std::int64_t value;
            if (first >= static_cast<int>(right) || last <= static_cast<int>(left) || first > last) value = 2 * inner + 2;
            else if (first == last) value = 2 * inner + 1;
            else value = 2 * inner - (first + 1 <= last - 1 ? dp[static_cast<std::size_t>(first + 1)][static_cast<std::size_t>(last - 1)] : 0);
            dp[left][right] = normalize(value);
        }
    }
    return dp[0][n - 1];
}
