#include <cstddef>
#include <cstdint>

namespace {
std::int64_t gcd_i64(std::int64_t a, std::int64_t b) noexcept {
    while (b != 0) { const auto remainder = a % b; a = b; b = remainder; }
    return a;
}

std::int64_t pow_mod_i64(std::int64_t base, std::int64_t exponent, std::int64_t modulus) noexcept {
    std::int64_t result = 1;
    base %= modulus;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent /= 2;
    }
    return result;
}

std::int64_t totient_i64(std::int64_t value) noexcept {
    auto remaining = value;
    auto result = value;
    for (std::int64_t prime = 2; prime * prime <= remaining; ++prime) {
        if (remaining % prime == 0) {
            result = result / prime * (prime - 1);
            do { remaining /= prime; } while (remaining % prime == 0);
        }
    }
    if (remaining > 1) result = result / remaining * (remaining - 1);
    return result;
}

std::int64_t reduce_order(std::int64_t base, std::int64_t modulus, std::int64_t order) noexcept {
    auto remaining = order;
    for (std::int64_t prime = 2; prime * prime <= remaining; ++prime) {
        if (remaining % prime == 0) {
            do { remaining /= prime; } while (remaining % prime == 0);
            while (order % prime == 0 && pow_mod_i64(base, order / prime, modulus) == 1) order /= prime;
        }
    }
    if (remaining > 1)
        while (order % remaining == 0 && pow_mod_i64(base, order / remaining, modulus) == 1) order /= remaining;
    return order;
}
}

extern "C" std::int64_t multiplicative_order(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 2) return -1;
    const auto base = input[0], modulus = input[1];
    if (modulus < 2 || modulus > 1000 || base < 0 || base >= modulus) return -1;
    if (gcd_i64(base, modulus) != 1) return 0;
    return reduce_order(base, modulus, totient_i64(modulus));
}
