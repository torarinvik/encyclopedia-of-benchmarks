/* Encode ascending prime/exponent pairs as little-endian u32 values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT INT64_C(1000005)

static size_t factor_pairs(int64_t value, uint32_t primes[10], uint32_t exponents[10])
{
    if (value <= 1) { primes[0] = (uint32_t)value; exponents[0] = 1; return 1; }
    size_t count = 0;
    int64_t remaining = value;
    for (int64_t divisor = 2; divisor <= remaining / divisor; ++divisor) {
        if (remaining % divisor == 0) {
            uint32_t exponent = 0;
            do { remaining /= divisor; ++exponent; } while (remaining % divisor == 0);
            primes[count] = (uint32_t)divisor;
            exponents[count++] = exponent;
        }
    }
    if (remaining > 1) { primes[count] = (uint32_t)remaining; exponents[count++] = 1; }
    return count;
}

static void write_u32le(uint32_t value, uint8_t *output)
{
    for (unsigned byte = 0; byte < 4; ++byte) output[byte] = (uint8_t)(value >> (8 * byte));
}

int64_t factorize(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 0 || value > MAX_INPUT) return -1;
    uint32_t primes[10], exponents[10];
    const size_t count = factor_pairs(value, primes, exponents);
    const size_t required = count * 8;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t i = 0; i < count; ++i) {
        write_u32le(primes[i], output + 8 * i);
        write_u32le(exponents[i], output + 8 * i + 4);
    }
    return (int64_t)required;
}
