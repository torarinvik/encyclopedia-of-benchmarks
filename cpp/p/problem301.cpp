/* Match the pinned source: odd exponents return F(exponent + 2) - 1. */
#include <cstdint>

extern "C" std::int64_t problem301(std::int64_t exponent) noexcept
{
    if (exponent < 0 || exponent > 30) return -1;
    std::int64_t previous = 0, current = 1;
    for (std::int64_t index = 0; index < exponent + 2; ++index) {
        const std::int64_t next = previous + current;
        previous = current;
        current = next;
    }
    return previous - (exponent % 2);
}
