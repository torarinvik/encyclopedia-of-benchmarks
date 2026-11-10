/* Return the exact zero-based Catalan number through the signed 64-bit range. */
#include <cstdint>

extern "C" std::int64_t catalan_number(std::int64_t n) noexcept
{
    if (n < 0 || n > 35) return -1;
    std::int64_t value = 1;
    for (std::int64_t index = 1; index <= n; ++index) {
        std::int64_t numerator = 4 * index - 2;
        std::int64_t denominator = index + 1;
        const std::int64_t common = (denominator % 3 == 0 ? 3 : 1) * (denominator % 2 == 0 ? 2 : 1);
        numerator /= common;
        denominator /= common;
        value = (value / denominator) * numerator;
    }
    return value;
}
