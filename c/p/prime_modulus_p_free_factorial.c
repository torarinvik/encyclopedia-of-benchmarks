#include <stddef.h>
#include <stdint.h>

#define MAX_PRIME 1009
#define MAX_PARSEABLE_LENGTH 3

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    if (value % 2 == 0) return value == 2;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

int64_t prime_modulus_p_free_factorial(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 2) return -1;
    const int64_t n = input[0];
    const int64_t prime = input[1];
    if (n < 0 || prime < 2 || prime > MAX_PRIME || !is_prime(prime)) return -1;

    int64_t factorial[MAX_PRIME];
    factorial[0] = 1;
    for (int64_t i = 1; i < prime; ++i)
        factorial[i] = (factorial[i - 1] * i) % prime;

    int64_t result = 1;
    int64_t remaining = n;
    while (remaining > 0) {
        const int64_t quotient = remaining / prime;
        const int64_t residue = remaining % prime;
        result = (result * factorial[residue]) % prime;
        if ((quotient & 1) != 0) result = prime - result;
        remaining = quotient;
    }
    return result;
}
