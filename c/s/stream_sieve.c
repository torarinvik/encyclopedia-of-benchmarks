/* Extend and reuse one process-wide prime prefix, like the source LazyList. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PRIMES 100

static int32_t prime_cache[MAX_PRIMES] = {2};
static size_t prime_count = 1;
static int32_t next_candidate = 3;

static int is_prime_candidate(int32_t candidate)
{
    for (size_t index = 0; index < prime_count; ++index) {
        const int32_t divisor = prime_cache[index];
        if (divisor > candidate / divisor) break;
        if (candidate % divisor == 0) return 0;
    }
    return 1;
}

static void extend_prime_cache(size_t requested_count)
{
    while (prime_count < requested_count) {
        const int32_t candidate = next_candidate;
        ++next_candidate;
        if (is_prime_candidate(candidate)) prime_cache[prime_count++] = candidate;
    }
}

int64_t stream_sieve(int64_t number_of_primes, uint8_t *output, size_t output_capacity)
{
    if (number_of_primes < INT32_MIN || number_of_primes > MAX_PRIMES) return -1;
    if (number_of_primes <= 0) return 0;
    const size_t count = (size_t)number_of_primes;
    const size_t required = count * 4;
    if (output == NULL || output_capacity < required) return -2;

    extend_prime_cache(count);
    for (size_t index = 0; index < count; ++index) {
        const uint32_t bits = (uint32_t)prime_cache[index];
        for (size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)required;
}
