/* Solve pairwise-coprime congruences with incremental CRT and extended Euclid. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_inputs = 8;
constexpr std::int64_t max_modulus = 1000;

std::int64_t modular_inverse(std::int64_t value, std::int64_t modulus) noexcept
{
    std::int64_t old_remainder = value % modulus;
    std::int64_t remainder = modulus;
    std::int64_t old_coefficient = 1;
    std::int64_t coefficient = 0;
    while (remainder != 0) {
        const std::int64_t quotient = old_remainder / remainder;
        const std::int64_t next_remainder = old_remainder - quotient * remainder;
        old_remainder = remainder;
        remainder = next_remainder;
        const std::int64_t next_coefficient = old_coefficient - quotient * coefficient;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if (old_remainder != 1) return -1;
    old_coefficient %= modulus;
    return old_coefficient < 0 ? old_coefficient + modulus : old_coefficient;
}
}

extern "C" std::int64_t chinese_remainder_theorem(const std::int64_t *values,
                                                   std::size_t length) noexcept
{
    if (length < 2 || length > max_inputs || length % 2 != 0) return -1;
    std::int64_t result = 0;
    std::int64_t product = 1;
    for (std::size_t index = 0; index < length; index += 2) {
        const std::int64_t residue = values[index];
        const std::int64_t modulus = values[index + 1];
        if (modulus < 2 || modulus > max_modulus || residue < 0 || residue >= modulus) return -1;
        const std::int64_t inverse = modular_inverse(product % modulus, modulus);
        if (inverse < 0) return -1;
        std::int64_t difference = residue - result % modulus;
        if (difference < 0) difference += modulus;
        const std::int64_t factor = (difference * inverse) % modulus;
        result += product * factor;
        product *= modulus;
    }
    return result;
}
