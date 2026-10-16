#include <cstdint>

namespace {
std::int64_t normalized_mod(std::int64_t value, std::int64_t modulus)
{
    std::int64_t remainder = value % modulus;
    if (remainder < 0) remainder += modulus;
    return remainder;
}
}

extern "C" std::int64_t modular_inverse(std::int64_t a, std::int64_t modulus) noexcept
{
    if (a < 0 || a > 1'000'000 || modulus < 2 || modulus > 1'000'000) return -1;

    std::int64_t old_remainder = normalized_mod(a, modulus);
    std::int64_t remainder = modulus;
    std::int64_t old_coefficient = 1;
    std::int64_t coefficient = 0;
    while (remainder != 0) {
        const std::int64_t quotient = old_remainder / remainder;
        const std::int64_t next_remainder = old_remainder - quotient * remainder;
        const std::int64_t next_coefficient = old_coefficient - quotient * coefficient;
        old_remainder = remainder;
        remainder = next_remainder;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if (old_remainder != 1) return -1;
    return normalized_mod(old_coefficient, modulus);
}
