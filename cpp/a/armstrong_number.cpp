/* Independent portable implementation; upstream references are in the guide. */
#include <cstdint>

extern "C" std::int64_t armstrong_number(std::int64_t n) noexcept
{
    if (n < 0) return 0;
    if (n == 0) return 1;
    std::int64_t digits = 0;
    for (std::int64_t remaining = n; remaining > 0; remaining /= 10) ++digits;
    std::int64_t sum = 0;
    for (std::int64_t remaining = n; remaining > 0; remaining /= 10) {
        const std::int64_t digit = remaining % 10;
        std::int64_t power = 1;
        for (std::int64_t exponent = 0; exponent < digits; ++exponent) power *= digit;
        if (power > n - sum) return 0;
        sum += power;
    }
    return sum == n ? 1 : 0;
}
