/* Add the decimal digits of the absolute value of a signed 32-bit integer. */
#include <cstdint>

extern "C" std::int64_t sum_of_digits(std::int64_t input) noexcept
{
    if (input < INT32_MIN || input > INT32_MAX) return -1;
    const std::uint32_t magnitude = static_cast<std::uint32_t>(input < 0 ? -input : input);
    std::uint32_t remaining = magnitude;
    std::uint32_t total = 0;
    while (remaining >= 10) {
        const std::uint32_t next_quotient = remaining / 10;
        remaining /= 100;
        total += next_quotient + remaining;
    }
    return magnitude - 9 * total;
}
