#include <cstddef>
#include <cstdint>

namespace {
std::int64_t power_using_recursion_value(std::int64_t base, std::int64_t exponent)
{
    if (exponent == 0) return 1;
    return base * power_using_recursion_value(base, exponent - 1);
}
}

extern "C" std::int64_t power_using_recursion(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 2) return -1;
    const std::int64_t base = input[0];
    const std::int64_t exponent = input[1];
    if (base < -10 || base > 10 || exponent < 0 || exponent > 15) return -1;
    return power_using_recursion_value(base, exponent);
}
