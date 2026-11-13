#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::array<std::int64_t, 18> SMALL_PRIMES = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61};

std::int64_t gcd_i64(std::int64_t left, std::int64_t right) {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t pow_mod_i64(std::int64_t base, std::int64_t exponent, std::int64_t modulus) {
    std::int64_t result = 1;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}
}

extern "C" std::int64_t pollard_p_minus_one_factorization(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 3) return -1;
    const auto number = input[0], bound = input[1], initial = input[2];
    if (number < 2 || number > 1000000000 || bound < 2 || bound > 64 || initial < 1 || initial >= number) return -1;
    auto divisor = gcd_i64(initial, number);
    if (divisor > 1) return divisor;
    auto state = initial;
    for (const auto prime : SMALL_PRIMES) {
        if (prime > bound) break;
        auto exponent = prime;
        while (exponent <= bound / prime) exponent *= prime;
        state = pow_mod_i64(state, exponent, number);
        const auto difference = state >= 1 ? state - 1 : 1 - state;
        divisor = gcd_i64(difference, number);
        if (divisor > 1) return divisor < number ? divisor : 0;
    }
    return 0;
}
