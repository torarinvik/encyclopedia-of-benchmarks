/* Sum decimal digits raised to their one-based positions from the left. */
#include <cstdint>

extern "C" std::int64_t disarium_number(std::int64_t number) noexcept
{
    if (number < 1 || number > 99'999'999) return -1;
    std::int64_t digits = 0;
    for (auto remaining = number; remaining > 0; remaining /= 10) ++digits;
    auto position = digits;
    auto remaining = number;
    std::int64_t sum = 0;
    while (remaining > 0) {
        const auto digit = remaining % 10;
        std::int64_t power = 1;
        for (std::int64_t exponent = 0; exponent < position; ++exponent) power *= digit;
        sum += power;
        --position;
        remaining /= 10;
    }
    return sum == number ? 1 : 0;
}
