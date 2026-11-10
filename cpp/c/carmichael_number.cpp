#include <cstdint>

namespace {
bool is_composite(std::int64_t n)
{
    if (n < 4) return false;
    for (std::int64_t divisor = 2; divisor <= n / divisor; ++divisor) {
        if (n % divisor == 0) return true;
    }
    return false;
}

std::int64_t modular_power(std::int64_t base, std::int64_t exponent, std::int64_t modulus)
{
    std::int64_t result = 1;
    std::int64_t power = base;
    std::int64_t remaining = exponent;
    while (remaining > 0) {
        if (remaining % 2 != 0) result = (result * power) % modulus;
        remaining /= 2;
        if (remaining > 0) power = (power * power) % modulus;
    }
    return result;
}

std::int64_t gcd(std::int64_t left, std::int64_t right)
{
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}
} // namespace

extern "C" std::int64_t carmichael_number(std::int64_t value) noexcept
{
    if (value < 1 || value > 10000) return -1;
    if (value < 3 || !is_composite(value)) return 0;
    for (std::int64_t base = 2; base < value; ++base) {
        if (gcd(base, value) == 1 && modular_power(base, value - 1, value) != 1) return 0;
    }
    return 1;
}
