/* Return the source's extracted hexadecimal digit as a numeric nibble. */
#include <cmath>
#include <cstdint>

static std::int64_t modular_power_16(std::int64_t exponent, std::int64_t modulus)
{
    std::int64_t result = 1 % modulus;
    std::int64_t base = 16 % modulus;
    while (exponent > 0) {
        if (exponent & 1) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static double bbp_subsum(std::int64_t position, std::int64_t addend)
{
    double total = 0.0;
    for (std::int64_t index = 0; index < position + 1000; ++index) {
        const std::int64_t denominator = 8 * index + addend;
        const std::int64_t exponent = position - 1 - index;
        const double term = index < position
            ? static_cast<double>(modular_power_16(exponent, denominator)) / static_cast<double>(denominator)
            : std::pow(16.0, static_cast<double>(exponent)) / static_cast<double>(denominator);
        total += term;
    }
    return total;
}

extern "C" std::int64_t bailey_borwein_plouffe(std::int64_t digit_position) noexcept
{
    if (digit_position < 1 || digit_position > 10) return -1;
    const double sum_result = 4.0 * bbp_subsum(digit_position, 1)
        - 2.0 * bbp_subsum(digit_position, 4)
        - bbp_subsum(digit_position, 5)
        - bbp_subsum(digit_position, 6);
    const double fractional = sum_result - std::floor(sum_result);
    return static_cast<std::int64_t>(fractional * 16.0);
}
