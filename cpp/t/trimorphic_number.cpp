/* Check whether n cubed ends with the decimal digits of n. */
#include <cstdint>

extern "C" std::int64_t trimorphic_number(std::int64_t number) noexcept
{
    if (number < 0 || number > 2000000) return -1;
    std::int64_t modulus = 10;
    auto digits = number;
    while (digits >= 10) { digits /= 10; modulus *= 10; }
    const auto cube = number * number * number;
    return cube % modulus == number ? 1 : 0;
}
