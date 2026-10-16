/* Count source-sequence prime candidates strictly below max_prime. */
#include <stdint.h>

#define MAX_PRIME INT64_C(1000000)

static int problem131_is_prime(int64_t number)
{
    if (number < 2) return 0;
    for (int64_t divisor = 2; divisor <= number / divisor; ++divisor) {
        if (number % divisor == 0) return 0;
    }
    return 1;
}

int64_t problem131(int64_t max_prime)
{
    if (max_prime < 0 || max_prime > MAX_PRIME) return -1;
    int64_t primes_count = 0;
    int64_t cube_index = 1;
    int64_t prime_candidate = 7;
    while (prime_candidate < max_prime) {
        primes_count += problem131_is_prime(prime_candidate);
        ++cube_index;
        prime_candidate += 6 * cube_index;
    }
    return primes_count;
}
