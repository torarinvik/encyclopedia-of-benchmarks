#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_N = 16;
constexpr std::int64_t MIN_BOUND = -10'000'000;
constexpr std::int64_t MAX_BOUND = 10'000'000;
constexpr std::int64_t MAX_UNIFORM = 999'999;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double monte_carlo_integration_independent(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 3 || length > 20) return INVALID_RESULT;
    const std::int64_t n = packed[2];
    if (n < 1 || n > MAX_N || length != static_cast<std::size_t>(3 + n)) return INVALID_RESULT;
    const auto a_raw = packed[0];
    const auto b_raw = packed[1];
    if (a_raw < MIN_BOUND || a_raw > MAX_BOUND || b_raw < MIN_BOUND || b_raw > MAX_BOUND || a_raw >= b_raw) return INVALID_RESULT;
    for (std::size_t index = 3; index < length; ++index) {
        if (packed[index] < 0 || packed[index] > MAX_UNIFORM) return INVALID_RESULT;
    }

    const double a = static_cast<double>(a_raw) / 1'000'000.0;
    const double b = static_cast<double>(b_raw) / 1'000'000.0;
    const double interval = b - a;
    const double delta = interval / static_cast<double>(n);
    double total = 0.0;
    for (std::int64_t index = 0; index < n; ++index) {
        const double u = static_cast<double>(packed[3 + static_cast<std::size_t>(index)]) / 1'000'000.0;
        const double x = a + interval * u;
        total += x * x;
    }
    return delta * total;
}
