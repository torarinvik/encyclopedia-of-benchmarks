/* Check whether the square ends with the original nonnegative integer. */
#include <cstdint>

namespace {
std::uint64_t add_mod(std::uint64_t left, std::uint64_t right, std::uint64_t modulus)
{
    return left >= modulus - right ? left - (modulus - right) : left + right;
}

std::uint64_t multiply_mod(std::uint64_t left, std::uint64_t right, std::uint64_t modulus)
{
    std::uint64_t result = 0;
    while (right != 0) {
        if ((right & 1u) != 0) result = add_mod(result, left, modulus);
        right >>= 1;
        if (right != 0) left = add_mod(left, left, modulus);
    }
    return result;
}
}

extern "C" std::int64_t automorphic_number(std::int64_t n) noexcept
{
    if (n < 0) return 0;
    const auto number = static_cast<std::uint64_t>(n);
    std::uint64_t modulus = 10;
    for (std::uint64_t digits = number; digits >= 10; digits /= 10) modulus *= 10;
    return multiply_mod(number, number, modulus) == number ? 1 : 0;
}
