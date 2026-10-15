#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_N = 64;
constexpr std::int64_t MAX_ABS_VALUE = 1'000'000;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double weighted_average(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 1 || length > 129) return INVALID_RESULT;
    const std::int64_t n = packed[0];
    if (n < 1 || n > MAX_N || length != static_cast<std::size_t>(1 + 2 * n)) return INVALID_RESULT;
    std::int64_t weighted_sum = 0;
    std::int64_t total_weight = 0;
    for (std::int64_t i = 0; i < n; ++i) {
        const auto value = packed[1 + static_cast<std::size_t>(i)];
        const auto weight = packed[1 + static_cast<std::size_t>(n) + static_cast<std::size_t>(i)];
        if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE ||
            weight < -MAX_ABS_VALUE || weight > MAX_ABS_VALUE) return INVALID_RESULT;
        weighted_sum += value * weight;
        total_weight += weight;
    }
    if (total_weight == 0) return INVALID_RESULT;
    return static_cast<double>(weighted_sum) / static_cast<double>(total_weight);
}
