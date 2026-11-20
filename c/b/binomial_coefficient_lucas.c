#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define BCL_MAX_PRIME INT64_C(1009)

static bool bcl_is_prime(int64_t value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

static int64_t bcl_modular_power(int64_t base, int64_t exponent,
                                 int64_t modulus) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

int64_t binomial_coefficient_lucas(const int64_t *input, size_t length) {
    if (input == NULL || length != 3) return -1;

    int64_t n = input[0];
    int64_t k = input[1];
    const int64_t prime = input[2];
    if (n < 0 || k < 0 || k > n || prime < 2 || prime > BCL_MAX_PRIME
        || !bcl_is_prime(prime)) {
        return -1;
    }

    int64_t factorial[BCL_MAX_PRIME];
    int64_t inverse_factorial[BCL_MAX_PRIME];
    factorial[0] = 1;
    for (int64_t i = 1; i < prime; ++i) {
        factorial[i] = factorial[i - 1] * i % prime;
    }

    inverse_factorial[prime - 1] =
        bcl_modular_power(factorial[prime - 1], prime - 2, prime);
    for (int64_t i = prime - 1; i > 0; --i) {
        inverse_factorial[i - 1] = inverse_factorial[i] * i % prime;
    }

    int64_t result = 1;
    while (n > 0 || k > 0) {
        const int64_t n_digit = n % prime;
        const int64_t k_digit = k % prime;
        if (k_digit > n_digit) return 0;

        int64_t digit_result = factorial[n_digit] * inverse_factorial[k_digit]
                             % prime;
        digit_result = digit_result * inverse_factorial[n_digit - k_digit]
                     % prime;
        result = result * digit_result % prime;
        n /= prime;
        k /= prime;
    }
    return result;
}
