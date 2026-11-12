#include <stddef.h>
#include <stdint.h>

enum {
    MAX_INPUT = 100000000,
    SIEVE_LIMIT = 10000,
    MAX_PRIMES = 1300,
    PHI_CACHE_X = 2048,
    PHI_CACHE_S = 32
};

typedef struct {
    uint8_t composite[SIEVE_LIMIT + 1];
    int32_t primes[MAX_PRIMES];
    int32_t prime_count_prefix[SIEVE_LIMIT + 1];
    int32_t phi_cache[PHI_CACHE_S + 1][PHI_CACHE_X + 1];
} prime_count_context;

static uint64_t integer_sqrt(uint64_t value) {
    uint64_t low = 0;
    uint64_t high = value + 1;
    while (low + 1 < high) {
        const uint64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

static uint64_t integer_cuberoot(uint64_t value) {
    uint64_t low = 0;
    uint64_t high = value + 1;
    while (low + 1 < high) {
        const uint64_t middle = low + (high - low) / 2;
        if (middle <= value / middle / middle) low = middle;
        else high = middle;
    }
    return low;
}

static int64_t count_phi(prime_count_context *context, uint64_t value, uint32_t prime_count) {
    if (value == 0) return 0;
    if (prime_count == 0) return (int64_t)value;
    if (prime_count == 1) return (int64_t)(value - value / 2);
    if (value < (uint64_t)context->primes[prime_count - 1]) return 1;
    if (value <= PHI_CACHE_X && prime_count <= PHI_CACHE_S) {
        const int32_t cached = context->phi_cache[prime_count][value];
        if (cached != 0) return cached;
        const int64_t result = count_phi(context, value, prime_count - 1) -
            count_phi(context, value / (uint64_t)context->primes[prime_count - 1], prime_count - 1);
        context->phi_cache[prime_count][value] = (int32_t)result;
        return result;
    }
    return count_phi(context, value, prime_count - 1) -
        count_phi(context, value / (uint64_t)context->primes[prime_count - 1], prime_count - 1);
}

static int64_t lehmer_count(prime_count_context *context, uint64_t value) {
    if (value <= SIEVE_LIMIT) return context->prime_count_prefix[value];
    const uint32_t a = (uint32_t)context->prime_count_prefix[integer_sqrt(integer_sqrt(value))];
    const uint32_t b = (uint32_t)context->prime_count_prefix[integer_sqrt(value)];
    const uint32_t c = (uint32_t)context->prime_count_prefix[integer_cuberoot(value)];
    int64_t result = count_phi(context, value, a) +
        (int64_t)(b + a - 2) * (int64_t)(b - a + 1) / 2;

    for (uint32_t i = a; i < b; ++i) {
        const uint64_t quotient = value / (uint64_t)context->primes[i];
        result -= lehmer_count(context, quotient);
        if (i < c) {
            const uint32_t limit = (uint32_t)lehmer_count(context, integer_sqrt(quotient));
            for (uint32_t j = i; j < limit; ++j)
                result -= lehmer_count(context, quotient / (uint64_t)context->primes[j]) - (int64_t)j;
        }
    }
    return result;
}

int64_t meissel_lehmer_prime_count(int64_t value) {
    if (value < 0 || value > MAX_INPUT) return -1;
    prime_count_context context = {0};
    for (int32_t candidate = 2; candidate * candidate <= SIEVE_LIMIT; ++candidate) {
        if (context.composite[candidate]) continue;
        for (int32_t multiple = candidate * candidate; multiple <= SIEVE_LIMIT; multiple += candidate)
            context.composite[multiple] = 1;
    }
    int32_t prime_count = 0;
    for (int32_t candidate = 2; candidate <= SIEVE_LIMIT; ++candidate) {
        if (!context.composite[candidate]) context.primes[prime_count++] = candidate;
        context.prime_count_prefix[candidate] = context.prime_count_prefix[candidate - 1] +
            (int32_t)!context.composite[candidate];
    }
    return lehmer_count(&context, (uint64_t)value);
}
