#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t strange_printer(const std::int64_t *input,
                                         std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 10) return -1;
    const auto n_raw = input[0];
    if (n_raw < 0 || n_raw > 8 || length != static_cast<std::size_t>(n_raw) + 1) return -1;
    const auto n = static_cast<std::size_t>(n_raw);
    for (std::size_t position = 0; position < n; ++position) {
        if (input[position + 1] < 0 || input[position + 1] > 2) return -1;
    }
    if (n == 0) return 0;

    std::array<std::int64_t, 81> dp{};
    for (std::size_t left = n; left-- > 0;) {
        dp[left * 9 + left] = 1;
        for (std::size_t right = left + 1; right < n; ++right) {
            auto best = dp[(left + 1) * 9 + right] + 1;
            for (std::size_t merge = left + 1; merge <= right; ++merge) {
                if (input[left + 1] != input[merge + 1]) continue;
                const auto middle = merge == left + 1 ? 0 : dp[(left + 1) * 9 + merge - 1];
                const auto candidate = middle + dp[merge * 9 + right];
                if (candidate < best) best = candidate;
            }
            dp[left * 9 + right] = best;
        }
    }
    return dp[n - 1];
}
