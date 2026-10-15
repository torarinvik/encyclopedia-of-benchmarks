// Count multiples of divisor in the inclusive positive integer interval [first, last].
#include <cstdint>

extern "C" double count_numbers_divisible(double first, double last, double divisor) noexcept
{
    const auto a = static_cast<std::int64_t>(first);
    const auto b = static_cast<std::int64_t>(last);
    const auto m = static_cast<std::int64_t>(divisor);
    return static_cast<double>(b / m - (a - 1) / m);
}
