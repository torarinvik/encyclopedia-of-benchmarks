/* Count the primes through limit using the Sieve of Eratosthenes. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LIMIT INT64_C(4096)

int64_t sieve_of_eratosthenes(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    uint8_t prime[4097] = {0};
    for (int64_t value = 2; value <= limit; ++value) prime[value] = 1;
    for (int64_t factor = 2; factor <= limit / factor; ++factor) {
        if (prime[factor]) {
            for (int64_t multiple = factor * factor; multiple <= limit; multiple += factor)
                prime[multiple] = 0;
        }
    }
    int64_t count = 0;
    for (int64_t value = 2; value <= limit; ++value) count += prime[value] != 0;
    return count;
}
