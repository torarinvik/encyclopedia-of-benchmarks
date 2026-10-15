// Check whether n is an Armstrong number in base 10.
#include <cstdint>

extern "C" std::int64_t armstrong(std::int64_t n) noexcept
{
    if (n < -INT64_C(2147483648) || n > INT64_C(2147483647)) return -1;
    if (n < 0) return 0;
    if (n == 0) return 1;

    const std::int64_t original = n;
    std::int64_t remaining = n;
    std::int64_t digits = 0;
    while (remaining > 0) {
        ++digits;
        remaining /= 10;
    }

    std::int64_t sum = 0;
    remaining = n;
    while (remaining > 0) {
        const std::int64_t digit = remaining % 10;
        std::int64_t power = 1;
        for (std::int64_t exponent = 0; exponent < digits; ++exponent) power *= digit;
        sum += power;
        remaining /= 10;
    }
    return sum == original ? 1 : 0;
}
