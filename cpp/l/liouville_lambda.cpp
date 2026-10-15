/* Liouville's function: (-1) raised to the number of prime factors with multiplicity. */
#include <cstdint>

extern "C" std::int64_t liouville_lambda(std::int64_t input) noexcept
{
    if (input < 1 || input > 2147483647) return -1;
    auto remaining = static_cast<std::uint64_t>(input);
    std::int64_t sign = 1;
    for (std::uint64_t factor = 2; factor <= remaining / factor;
         factor += factor == 2 ? 1 : 2) {
        while (remaining % factor == 0) {
            remaining /= factor;
            sign = -sign;
        }
    }
    if (remaining > 1) sign = -sign;
    return sign;
}
