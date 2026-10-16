#include <cstdint>

namespace {
std::int64_t choose_ten(std::int64_t n) noexcept
{
    std::int64_t result = 1;
    for (std::int64_t i = 0; i < 10; ++i) result = result * (n - i) / (i + 1);
    return result;
}
}

extern "C" std::int64_t problem493(std::int64_t picks) noexcept
{
    if (picks < 0 || picks > 70) return -1;
    const auto denominator = choose_ten(70);
    const auto missing = picks > 60 ? 0 : choose_ten(70 - picks);
    const auto numerator = 7 * (denominator - missing);
    const auto whole = numerator / denominator;
    auto remainder = numerator % denominator;
    std::int64_t fraction = 0;
    for (int i = 0; i < 9; ++i) { remainder *= 10; fraction = fraction * 10 + remainder / denominator; remainder %= denominator; }
    remainder *= 10;
    const auto guard = remainder / denominator;
    remainder %= denominator;
    auto scaled = whole * INT64_C(1000000000) + fraction;
    if (guard > 5 || (guard == 5 && (remainder > 0 || scaled % 2 != 0))) ++scaled;
    return scaled;
}
