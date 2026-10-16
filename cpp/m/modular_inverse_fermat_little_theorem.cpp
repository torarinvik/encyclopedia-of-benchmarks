#include <cstdint>

namespace {
std::int64_t binary_exponentiation(std::int64_t base, std::int64_t exponent,
                                   std::int64_t modulus) noexcept {
    base %= modulus;
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

bool is_prime(std::int64_t value) noexcept {
    if (value <= 1) return false;
    for (std::int64_t divisor = 2; divisor * divisor <= value; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}
}

extern "C" std::int64_t modular_inverse_fermat_little_theorem(
    std::int64_t a, std::int64_t m) noexcept {
    if (a < -1'000'000 || a > 1'000'000 || m < 2 || m > 1'000'000 ||
        a == 0 || a <= -m || a >= m || !is_prime(m)) return -1;
    while (a < 0) a += m;
    return binary_exponentiation(a, m - 2, m);
}
