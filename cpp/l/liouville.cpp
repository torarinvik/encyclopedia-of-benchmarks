/* Go's distinct-factor Liouville variant: (-1) raised to omega(n). */
#include <cstdint>

extern "C" std::int64_t liouville(std::int64_t input) noexcept
{
    if (input < 1 || input > 2147483647) return -2;
    auto remaining = static_cast<std::uint64_t>(input);
    std::int64_t sign = 1;
    for (std::uint64_t factor = 2; factor <= remaining / factor;
         factor += factor == 2 ? 1 : 2) {
        if (remaining % factor == 0) {
            sign = -sign;
            while (remaining % factor == 0) remaining /= factor;
        }
    }
    if (remaining > 1) sign = -sign;
    return sign;
}
