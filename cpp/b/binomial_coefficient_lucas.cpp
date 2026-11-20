#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_prime = 1009;

bool is_prime(std::int64_t value) noexcept {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

std::int64_t modular_power(std::int64_t base, std::int64_t exponent,
                           std::int64_t modulus) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
} // namespace

extern "C" std::int64_t binomial_coefficient_lucas(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 3) return -1;

    std::int64_t n = input[0];
    std::int64_t k = input[1];
    const std::int64_t prime = input[2];
    if (n < 0 || k < 0 || k > n || prime < 2 || prime > max_prime
        || !is_prime(prime)) {
        return -1;
    }

    std::int64_t factorial[max_prime]{};
    std::int64_t inverse_factorial[max_prime]{};
    factorial[0] = 1;
    for (std::int64_t i = 1; i < prime; ++i) {
        factorial[i] = factorial[i - 1] * i % prime;
    }

    inverse_factorial[prime - 1] =
        modular_power(factorial[prime - 1], prime - 2, prime);
    for (std::int64_t i = prime - 1; i > 0; --i) {
        inverse_factorial[i - 1] = inverse_factorial[i] * i % prime;
    }

    std::int64_t result = 1;
    while (n > 0 || k > 0) {
        const std::int64_t n_digit = n % prime;
        const std::int64_t k_digit = k % prime;
        if (k_digit > n_digit) return 0;

        std::int64_t digit_result = factorial[n_digit]
                                  * inverse_factorial[k_digit] % prime;
        digit_result = digit_result * inverse_factorial[n_digit - k_digit]
                     % prime;
        result = result * digit_result % prime;
        n /= prime;
        k /= prime;
    }
    return result;
}
