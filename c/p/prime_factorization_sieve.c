/* Sieve through n, then emit ascending prime/exponent pairs as little-endian u32 values. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define MAX_INPUT INT64_C(1000005)
#define MAX_DISTINCT_FACTORS 10

static void write_u32le(uint32_t value, uint8_t *output)
{
    for (unsigned byte = 0; byte < 4; ++byte) output[byte] = (uint8_t)(value >> (8 * byte));
}

int64_t prime_factorization_sieve(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 1 || value > MAX_INPUT) return -1;
    if (value == 1) return 0;

    const size_t limit = (size_t)value;
    uint8_t *is_prime = malloc(limit + 1);
    if (is_prime == NULL) return -2;
    memset(is_prime, 1, limit + 1);
    is_prime[0] = 0;
    is_prime[1] = 0;
    for (size_t prime = 2; prime <= limit / prime; ++prime) {
        if (!is_prime[prime]) continue;
        for (size_t multiple = prime * prime; multiple <= limit; multiple += prime)
            is_prime[multiple] = 0;
    }

    uint32_t primes[MAX_DISTINCT_FACTORS], exponents[MAX_DISTINCT_FACTORS];
    size_t count = 0;
    int64_t remaining = value;
    for (size_t prime = 2; prime <= limit && remaining > 1; ++prime) {
        if (!is_prime[prime]) continue;
        uint32_t exponent = 0;
        while (remaining % (int64_t)prime == 0) {
            remaining /= (int64_t)prime;
            ++exponent;
        }
        if (exponent != 0) {
            primes[count] = (uint32_t)prime;
            exponents[count++] = exponent;
        }
    }
    free(is_prime);

    const size_t required = count * 8;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t index = 0; index < count; ++index) {
        write_u32le(primes[index], output + 8 * index);
        write_u32le(exponents[index], output + 8 * index + 4);
    }
    return (int64_t)required;
}
