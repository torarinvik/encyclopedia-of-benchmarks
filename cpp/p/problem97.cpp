/* Return the unpadded decimal suffix of the non-Mersenne prime expression. */
#include <cstdint>

namespace {
constexpr std::int64_t MAX_DIGITS = 18;
constexpr std::int64_t POWER_EXPONENT = 7'830'457;

std::int64_t multiply_mod(std::int64_t left, std::int64_t right, std::int64_t modulus) noexcept
{
    std::int64_t result = 0;
    while (right > 0) {
        if (right % 2 != 0) result = (result + left) % modulus;
        left = (left + left) % modulus;
        right /= 2;
    }
    return result;
}
}

extern "C" std::int64_t problem97(std::int64_t digits) noexcept
{
    if (digits < 0 || digits > MAX_DIGITS) return -1;
    std::int64_t modulus = 1;
    for (std::int64_t index = 0; index < digits; ++index) modulus *= 10;
    std::int64_t power = 1 % modulus;
    std::int64_t base = 2 % modulus;
    auto exponent = POWER_EXPONENT;
    while (exponent > 0) {
        if (exponent % 2 != 0) power = multiply_mod(power, base, modulus);
        base = multiply_mod(base, base, modulus);
        exponent /= 2;
    }
    return (multiply_mod(28'433, power, modulus) + 1) % modulus;
}
