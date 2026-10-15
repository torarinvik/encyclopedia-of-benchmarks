#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t unique_subsequences_count(const int64_t *input, size_t length) {
    if (input == nullptr || length < 1 || length > 31) return -1;
    if (input[0] < 0 || input[0] > 30 || length != static_cast<size_t>(input[0]) + 1) return -1;
    const size_t n = static_cast<size_t>(input[0]);
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    std::array<int64_t, 31> dp{};
    for (size_t end = n; end > 0; --end) {
        const size_t i = end - 1;
        std::array<bool, 128> seen{};
        for (size_t j = i; j < n; ++j) {
            const size_t ch = static_cast<size_t>(input[j + 1]);
            if (seen[ch]) continue;
            seen[ch] = true;
            dp[i] += 1 + dp[j + 1];
        }
    }
    return dp[0];
}
