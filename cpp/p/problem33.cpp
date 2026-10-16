/* Bounded port of TheAlgorithms/Python Project Euler 33. */
#include <cstdint>

namespace {
std::int64_t gcd_i64(std::int64_t left, std::int64_t right) noexcept
{
    while (right != 0) {
        const std::int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}
}

extern "C" std::int64_t problem33(std::int64_t digit_len) noexcept
{
    if (digit_len < 0 || digit_len > 5) return -1;
    std::int64_t upper = 1;
    for (std::int64_t index = 0; index < digit_len; ++index) upper *= 10;

    double result = 1.0;
    std::int64_t denominator = 11;
    for (std::int64_t numerator = 11; numerator < upper; ++numerator) {
        while (denominator <= 99) {
            if (numerator != denominator && numerator % 10 == denominator / 10 &&
                denominator % 10 != 0 &&
                static_cast<double>(numerator / 10) / static_cast<double>(denominator % 10) ==
                    static_cast<double>(numerator) / static_cast<double>(denominator)) {
                const std::int64_t divisor = gcd_i64(numerator, denominator);
                result *= static_cast<double>(denominator / divisor) /
                          static_cast<double>(numerator / divisor);
            }
            ++denominator;
        }
        denominator = 10;
    }
    return static_cast<std::int64_t>(result);
}
