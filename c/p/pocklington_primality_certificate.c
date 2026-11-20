#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 65535, MAX_FACTORS = 6, MAX_EXPONENT = 16, MAX_LENGTH = 22 };

static int64_t gcd_i64(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor * divisor <= value;
         divisor = divisor == 2 ? 3 : divisor + 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static int64_t pow_mod(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    int64_t factor = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * factor) % modulus;
        factor = (factor * factor) % modulus;
        exponent >>= 1;
    }
    return result;
}

static int64_t verify_certificate(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_LENGTH) return -1;
    const int64_t n = values[0];
    const int64_t count = values[1];
    if (n < 3 || n > MAX_N || count < 1 || count > MAX_FACTORS) return -1;
    if (length != (size_t)(3 + 3 * count)) return -1;

    int64_t factored_part = 1;
    int64_t previous_prime = 1;
    for (int64_t index = 0; index < count; ++index) {
        const size_t offset = (size_t)(2 + 3 * index);
        const int64_t prime = values[offset];
        const int64_t exponent = values[offset + 1];
        const int64_t witness = values[offset + 2];
        if (prime <= previous_prime || prime < 2 || exponent < 1 || exponent > MAX_EXPONENT
            || witness < 1 || witness >= n || !is_prime(prime)) return -1;
        previous_prime = prime;
        for (int64_t power = 0; power < exponent; ++power) {
            if (factored_part > (n - 1) / prime) return -1;
            factored_part *= prime;
        }
    }
    const int64_t cofactor = values[2 + 3 * count];
    if (cofactor < 1 || cofactor >= n || factored_part * cofactor != n - 1) return -1;
    if (factored_part * factored_part <= n) return 0;

    for (int64_t index = 0; index < count; ++index) {
        const size_t offset = (size_t)(2 + 3 * index);
        const int64_t prime = values[offset];
        const int64_t witness = values[offset + 2];
        if (pow_mod(witness, n - 1, n) != 1) return 0;
        const int64_t reduced = pow_mod(witness, (n - 1) / prime, n);
        const int64_t difference = (reduced + n - 1) % n;
        if (gcd_i64(difference, n) != 1) return 0;
    }
    return 1;
}

int64_t pocklington_primality_certificate(const int64_t *input, size_t length) {
    return verify_certificate(input, length);
}
