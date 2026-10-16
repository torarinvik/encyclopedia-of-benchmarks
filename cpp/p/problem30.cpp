/* Sum fixed-range numbers equal to the fifth powers of their decimal digits. */
#include <cstdint>

namespace {
constexpr std::int64_t digit_fifth_power(std::int64_t digit) noexcept
{
    return digit * digit * digit * digit * digit;
}
}

extern "C" std::int64_t problem30(std::int64_t ignored) noexcept
{
    if (ignored != 0) return -1;
    std::int64_t total = 0;
    for (std::int64_t number = 1000; number < 1000000; ++number) {
        auto remaining = number;
        std::int64_t digit_sum = 0;
        while (remaining > 0) {
            digit_sum += digit_fifth_power(remaining % 10);
            remaining /= 10;
        }
        if (digit_sum == number) total += number;
    }
    return total;
}
