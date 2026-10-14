/* Return the exact zero-based Catalan number through the signed 64-bit range. */
#include <cstdint>

static std::int64_t gcd_i64(std::int64_t left, std::int64_t right) noexcept
{
    while (right != 0) {
        const std::int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

extern "C" std::int64_t catalan_number(std::int64_t n) noexcept
{
    if (n < 0 || n > 35) return -1;
    std::int64_t value = 1;
    for (std::int64_t index = 1; index <= n; ++index) {
        std::int64_t numerator = 4 * index - 2;
        std::int64_t denominator = index + 1;
        const std::int64_t common = gcd_i64(numerator, denominator);
        numerator /= common;
        denominator /= common;
        value = (value / denominator) * numerator;
    }
    return value;
}
