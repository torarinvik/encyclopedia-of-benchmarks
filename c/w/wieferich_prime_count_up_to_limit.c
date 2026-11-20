#include <stddef.h>
#include <stdint.h>

enum { MAX_LIMIT = 5000, MAX_PARSEABLE_LENGTH = 2 };

static int64_t modular_power(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static int64_t count_wieferich_primes(int64_t limit) {
    uint8_t prime[MAX_LIMIT + 1];
    for (int64_t n = 0; n <= limit; ++n) prime[n] = 1;
    prime[0] = 0;
    prime[1] = 0;
    for (int64_t divisor = 2; divisor <= limit / divisor; ++divisor) {
        if (!prime[divisor]) continue;
        for (int64_t multiple = divisor * divisor; multiple <= limit; multiple += divisor)
            prime[multiple] = 0;
    }
    int64_t count = 0;
    for (int64_t p = 3; p <= limit; p += 2) {
        if (prime[p] && modular_power(2, p - 1, p * p) == 1) ++count;
    }
    return count;
}

int64_t wieferich_prime_count_up_to_limit(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 2 || input[0] > MAX_LIMIT) return -1;
    return count_wieferich_primes(input[0]);
}
