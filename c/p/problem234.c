#include <stdint.h>

#define MAX_LIMIT INT64_C(999966663333)
#define SIEVE_CAP 1000100
#define PRIME_CAP 80000

int64_t problem234(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    uint8_t composite[SIEVE_CAP] = {0};
    int64_t primes[PRIME_CAP];
    int prime_count = 0;
    int64_t root = 0;
    while ((root + 1) <= limit / (root + 1)) ++root;
    const int sieve_end = (int)root + 100;
    for (int p = 2; p < sieve_end; ++p) {
        if (composite[p]) continue;
        primes[prime_count++] = p;
        if ((int64_t)p * p < sieve_end)
            for (int multiple = p * p; multiple < sieve_end; multiple += p) composite[multiple] = 1;
    }
    int64_t total = 0;
    int index = 0;
    int64_t p = primes[index];
    while (p * p <= limit) {
        const int64_t q = primes[index + 1];
        const int64_t lower = p * p;
        int64_t upper = q * q;
        int64_t current = lower + p;
        while (upper > current && current <= limit) { total += current; current += p; }
        while (upper - q > limit) upper -= q;
        current = upper - q;
        while (current > lower) { total += current; current -= q; }
        current = 0;
        while (upper > current && current <= limit) {
            if (current <= lower) { current += p * q; continue; }
            if (current > limit) break;
            total -= current * 2;
            current += p * q;
        }
        p = q;
        ++index;
    }
    return total;
}
