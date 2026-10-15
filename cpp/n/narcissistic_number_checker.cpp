/* Check whether n equals the sum of each decimal digit raised to digit count. */
#include <cstdint>

extern "C" std::int64_t narcissistic_number_checker(std::int64_t n) noexcept
{
    if (n < INT32_MIN || n > 999999) return -1;

    const std::int64_t original = n;
    std::int64_t remaining = n;
    std::int64_t digits = 0;
    while (remaining != 0) {
        ++digits;
        remaining /= 10;
    }

    std::int64_t sum = 0;
    while (n > 0) {
        const std::int64_t digit = n % 10;
        std::int64_t power = 1;
        for (std::int64_t exponent = 0; exponent < digits; ++exponent) power *= digit;
        sum += power;
        n /= 10;
    }
    return sum == original ? 1 : 0;
}
