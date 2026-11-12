#include <stdint.h>

enum { MAX_INPUT = 10000, SIEVE_LIMIT = 100, MAX_PRIMES = 25 };

static int64_t legendre_phi(const int64_t *primes, int64_t value, int64_t count)
{
    if (value == 0) return 0;
    if (count == 0) return value;
    if (count == 1) return value - value / 2;
    const int64_t prime = primes[count - 1];
    if (value < prime) return 1;
    return legendre_phi(primes, value, count - 1) -
        legendre_phi(primes, value / prime, count - 1);
}

int64_t legendre_prime_count(int64_t value)
{
    if (value < 0 || value > MAX_INPUT) return -1;
    if (value < 2) return 0;

    int64_t root = 0;
    while ((root + 1) * (root + 1) <= value) ++root;
    uint8_t composite[SIEVE_LIMIT + 1] = {0};
    for (int64_t candidate = 2; candidate * candidate <= root; ++candidate) {
        if (composite[candidate]) continue;
        for (int64_t multiple = candidate * candidate; multiple <= root; multiple += candidate)
            composite[multiple] = 1;
    }

    int64_t primes[MAX_PRIMES];
    int64_t count = 0;
    for (int64_t candidate = 2; candidate <= root; ++candidate)
        if (!composite[candidate]) primes[count++] = candidate;
    return legendre_phi(primes, value, count) + count - 1;
}
