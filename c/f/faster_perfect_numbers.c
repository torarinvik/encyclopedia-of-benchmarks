/* Generate perfect numbers through Lucas-Lehmer-tested Mersenne exponents. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT INT64_C(2305843009213693951)

static uint64_t get_prime_limit(int64_t value)
{
    uint64_t scaled = (uint64_t)value * UINT64_C(8) + UINT64_C(1);
    uint64_t limit = 0;
    while (scaled >= UINT64_C(4)) {
        scaled /= UINT64_C(4);
        ++limit;
    }
    return limit;
}

static int is_prime(uint64_t value)
{
    if (value < 2) return 0;
    for (uint64_t divisor = 2; divisor * divisor <= value; ++divisor)
        if (value % divisor == 0) return 0;
    return 1;
}

static int is_mersenne_prime(uint64_t exponent)
{
    if (exponent == 2) return 1;
    if (exponent < 2) return 0;
    const uint64_t modulus = (UINT64_C(1) << exponent) - UINT64_C(1);
    uint64_t residue = 4;
    for (uint64_t iteration = 0; iteration < exponent - 2; ++iteration)
        residue = (residue * residue - 2) % modulus;
    return residue == 0;
}

int64_t faster_perfect_numbers(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 0 || value > MAX_INPUT) return -1;
    int64_t perfects[8];
    size_t count = 0;
    const uint64_t limit = get_prime_limit(value);
    for (uint64_t exponent = 2; exponent <= limit; ++exponent) {
        if (!is_prime(exponent) || !is_mersenne_prime(exponent)) continue;
        const uint64_t mersenne = (UINT64_C(1) << exponent) - UINT64_C(1);
        const uint64_t perfect = mersenne * (UINT64_C(1) << (exponent - 1));
        if (perfect <= (uint64_t)value) perfects[count++] = (int64_t)perfect;
    }
    const size_t required = count * sizeof(int64_t);
    if (required > 0 && output == NULL) return -2;
    if (output_capacity < required) return -2;
    for (size_t index = 0; index < count; ++index) {
        const uint64_t bits = (uint64_t)perfects[index];
        for (size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)required;
}
