/* Expanding sieve strategy from the pinned Rust nth-prime routine. */
#include <stdint.h>

#define MAX_SIEVE_SIZE 1600

int64_t nthprime(int64_t nth)
{
    if (nth < 1 || nth > 100) return -1;
    uint64_t primes[MAX_SIEVE_SIZE];
    uint64_t total_prime = 0;
    uint64_t size_factor = 2;
    uint64_t size = (uint64_t)nth * size_factor;

    while (total_prime < (uint64_t)nth) {
        if (size > MAX_SIEVE_SIZE) return -1;
        for (uint64_t index = 0; index < size; ++index) primes[index] = 1;
        for (uint64_t index = 2; index < size; ++index) {
            if (primes[index] == 1) {
                for (uint64_t multiple = index; multiple < size; ++multiple) {
                    const uint64_t product = index * multiple;
                    if (product < size) primes[product] = 0;
                    else break;
                }
            }
        }
        total_prime = 0;
        for (uint64_t index = 2; index < size; ++index) total_prime += primes[index];
        ++size_factor;
        size = (uint64_t)nth * size_factor;
    }

    const uint64_t used_size = size - (uint64_t)nth;
    uint64_t count = 0;
    for (uint64_t index = 2; index < used_size; ++index) {
        count += primes[index];
        if (count == (uint64_t)nth) return (int64_t)index;
    }
    return -1;
}
