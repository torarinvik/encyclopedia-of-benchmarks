/* Check whether the packed values match the generated Golomb prefix. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t golomb_sequence_validator(const std::int64_t *input,
                                                    std::size_t length) noexcept
{
    constexpr std::size_t MAX_N = 1024;
    if (input == nullptr || length < 1 || length > MAX_N) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n) return -1;
    for (std::size_t index = 1; index < n; ++index)
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;

    std::array<std::int64_t, MAX_N> dp{};
    dp[0] = 1;
    for (std::size_t i = 1; i < n; ++i) {
        const auto previous = static_cast<std::size_t>(dp[i - 1]);
        const auto nested = static_cast<std::size_t>(dp[previous]);
        const auto source = i - nested;
        dp[i] = 1 + dp[source];
    }
    for (std::size_t index = 1; index < n; ++index)
        if (input[index] != dp[index]) return 0;
    return 1;
}
