#include <stdint.h>

#define MAX_INDEX INT64_C(999)
#define MAX_PRIMES 168

int64_t prime_pi_sequence(int64_t index)
{
    if (index < 0 || index > MAX_INDEX) return -1;
    const int64_t target = index + 1;
    int64_t primes[MAX_PRIMES];
    int64_t prime_count = 0;
    if (target >= 2) primes[prime_count++] = 2;
    for (int64_t candidate = 3; candidate <= target; candidate += 2) {
        int is_prime = 1;
        for (int64_t i = 0; i < prime_count; ++i) {
            if (candidate % primes[i] == 0) {
                is_prime = 0;
                break;
            }
        }
        if (is_prime) primes[prime_count++] = candidate;
    }
    return prime_count;
}
