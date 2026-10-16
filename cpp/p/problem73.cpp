/* Count reduced fractions strictly between 1/3 and 1/2. */
#include <cstdint>

namespace {
constexpr std::int64_t MAX_DENOMINATOR = 12000;

std::int64_t gcd_i64(std::int64_t left, std::int64_t right)
{
    while (right != 0) {
        const std::int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}
}

extern "C" std::int64_t problem73(std::int64_t max_denominator) noexcept
{
    if (max_denominator < 0 || max_denominator > MAX_DENOMINATOR) return -1;
    std::int64_t count = 0;
    for (std::int64_t denominator = 0; denominator <= max_denominator; ++denominator) {
        std::int64_t numerator_start = denominator / 3 + 1;
        std::int64_t numerator_step = 1;
        if (denominator % 2 == 0) {
            numerator_start += 1 - numerator_start % 2;
            numerator_step = 2;
        }
        const std::int64_t numerator_end = (denominator + 1) / 2;
        for (std::int64_t numerator = numerator_start; numerator < numerator_end;
             numerator += numerator_step) {
            if (gcd_i64(numerator, denominator) == 1) ++count;
        }
    }
    return count;
}
