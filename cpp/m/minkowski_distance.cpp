#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_N = 8;
constexpr std::int64_t MAX_P = 6;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double minkowski_distance(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 2 || length > 18) return INVALID_RESULT;
    const std::int64_t n = packed[0];
    const std::int64_t p = packed[1];
    if (n < 0 || n > MAX_N || p < 3 || p > MAX_P || length != static_cast<std::size_t>(2 + 2 * n)) return INVALID_RESULT;
    for (std::int64_t i = 0; i < n; ++i) {
        if (packed[2 + static_cast<std::size_t>(i)] < -100 || packed[2 + static_cast<std::size_t>(i)] > 100 ||
            packed[2 + static_cast<std::size_t>(n) + static_cast<std::size_t>(i)] < -100 ||
            packed[2 + static_cast<std::size_t>(n) + static_cast<std::size_t>(i)] > 100) return INVALID_RESULT;
    }
    std::int64_t sum = 0;
    for (std::int64_t i = 0; i < n; ++i) {
        std::int64_t difference = packed[2 + static_cast<std::size_t>(i)]
            - packed[2 + static_cast<std::size_t>(n) + static_cast<std::size_t>(i)];
        if (difference < 0) difference = -difference;
        std::int64_t term = 1;
        for (std::int64_t exponent = 0; exponent < p; ++exponent) term *= difference;
        sum += term;
    }
    return std::pow(static_cast<double>(sum), 1.0 / static_cast<double>(p));
}
