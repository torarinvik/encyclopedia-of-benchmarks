/* Prime-exponent factorial using binary buckets and balanced powers. */
#include <stdint.h>

#define MAX_N 20
#define MAX_BUCKETS 8

static int64_t exponent_in_factorial(int64_t prime, int64_t n)
{
    int64_t exponent = 0;
    int64_t quotient = n / prime;
    while (quotient > 0) {
        exponent += quotient;
        quotient /= prime;
    }
    return exponent;
}

static int64_t power_by_squaring(int64_t base, uint32_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1u) != 0) result *= base;
        exponent >>= 1;
        if (exponent > 0) base *= base;
    }
    return result;
}

int64_t fast_factorial(int64_t n)
{
    if (n < 0 || n > MAX_N) return -1;
    if (n < 2) return 1;

    uint8_t is_prime[MAX_N + 1] = {0};
    for (int64_t candidate = 2; candidate <= n; ++candidate) is_prime[candidate] = 1;
    for (int64_t prime = 2; prime * prime <= n; ++prime) {
        if (!is_prime[prime]) continue;
        for (int64_t multiple = prime * prime; multiple <= n; multiple += prime)
            is_prime[multiple] = 0;
    }

    const int64_t exponent_of_two = exponent_in_factorial(2, n);
    int64_t next_power_of_two = 1;
    uint32_t power_log2 = 0;
    while (next_power_of_two < exponent_of_two) {
        next_power_of_two <<= 1;
        ++power_log2;
    }
    const uint32_t bucket_count = power_log2 + 1;
    int64_t buckets[MAX_BUCKETS];
    for (uint32_t bit = 0; bit < MAX_BUCKETS; ++bit) buckets[bit] = 1;

    for (int64_t prime = 2; prime <= n; ++prime) {
        if (!is_prime[prime]) continue;
        const uint32_t exponent_bits = (uint32_t)exponent_in_factorial(prime, n);
        for (uint32_t bit = 0; bit < bucket_count; ++bit) {
            if ((exponent_bits & (1u << bit)) != 0) buckets[bit] *= prime;
        }
    }

    int64_t result = 1;
    for (uint32_t bit = 0; bit < bucket_count; ++bit)
        result *= power_by_squaring(buckets[bit], 1u << bit);
    return result;
}
