#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 1024;
constexpr std::size_t max_parseable_length = 2;

std::int64_t gcd_i64(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t lcm_i64(std::int64_t left, std::int64_t right) noexcept {
    return left / gcd_i64(left, right) * right;
}

std::int64_t prime_power_lambda(std::int64_t prime, int exponent,
                                std::int64_t power) noexcept {
    if (prime == 2) {
        if (exponent == 1) return 1;
        if (exponent == 2) return 2;
        return power / 4;
    }
    return (power / prime) * (prime - 1);
}

std::int64_t factorization_lambda(std::int64_t n) noexcept {
    if (n == 1) return 1;
    auto remaining = n;
    std::int64_t result = 1;
    for (std::int64_t prime = 2; prime * prime <= remaining;
         prime = (prime == 2 ? 3 : prime + 2)) {
        if (remaining % prime != 0) continue;
        int exponent = 0;
        std::int64_t power = 1;
        do {
            remaining /= prime;
            power *= prime;
            ++exponent;
        } while (remaining % prime == 0);
        result = lcm_i64(result, prime_power_lambda(prime, exponent, power));
    }
    if (remaining > 1) result = lcm_i64(result, remaining - 1);
    return result;
}
}

extern "C" std::int64_t carmichael_lambda_function(const std::int64_t* input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const auto n = input[0];
    if (n < 1 || n > max_n || length != 1) return -1;
    return factorization_lambda(n);
}
