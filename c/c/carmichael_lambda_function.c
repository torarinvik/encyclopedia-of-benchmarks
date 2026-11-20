#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 1024, MAX_PARSEABLE_LENGTH = 2 };

static int64_t gcd_i64(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int64_t lcm_i64(int64_t left, int64_t right) {
    return left / gcd_i64(left, right) * right;
}

static int64_t prime_power_lambda(int64_t prime, int exponent, int64_t power) {
    if (prime == 2) {
        if (exponent == 1) return 1;
        if (exponent == 2) return 2;
        return power / 4;
    }
    return (power / prime) * (prime - 1);
}

static int64_t factorization_lambda(int64_t n) {
    if (n == 1) return 1;
    int64_t remaining = n;
    int64_t result = 1;
    for (int64_t prime = 2; prime * prime <= remaining; prime = (prime == 2 ? 3 : prime + 2)) {
        if (remaining % prime != 0) continue;
        int exponent = 0;
        int64_t power = 1;
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

int64_t carmichael_lambda_function(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n = input[0];
    if (n < 1 || n > MAX_N || length != 1) return -1;
    return factorization_lambda(n);
}
