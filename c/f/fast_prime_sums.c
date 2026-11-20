#include <stdint.h>

enum {
    SIEVE_LIMIT = 32000,
    PRIME_CAPACITY = 3500,
    PHI_ROWS = 12,
    PHI_COLUMNS = 30000
};

typedef struct {
    uint8_t composite[SIEVE_LIMIT + 1];
    int32_t primes[PRIME_CAPACITY];
    int32_t prime_count[SIEVE_LIMIT + 1];
    int64_t prime_sum[SIEVE_LIMIT + 1];
    int64_t phi[PHI_ROWS * PHI_COLUMNS];
} prime_sum_context;

static int64_t integer_sqrt(int64_t value) {
    int64_t low = 0;
    int64_t high = value + 1;
    while (low + 1 < high) {
        const int64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

static int64_t integer_cuberoot(int64_t value) {
    int64_t low = 0;
    int64_t high = 1;
    while (high * high * high <= value) high *= 2;
    while (low + 1 < high) {
        const int64_t middle = low + (high - low) / 2;
        if (middle * middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

static int64_t weighted_phi(prime_sum_context *context, int64_t value, int32_t count) {
    if (value <= 0) return 0;
    if (count == 0) return value * (value + 1) / 2;
    const int64_t prime = context->primes[count - 1];
    if (value <= prime) return 1;
    if (count < PHI_ROWS && value < PHI_COLUMNS)
        return context->phi[count * PHI_COLUMNS + value];
    if (value < SIEVE_LIMIT && prime * prime >= value)
        return context->prime_sum[value] - context->prime_sum[prime] + 1;
    if (value < SIEVE_LIMIT && prime * prime * prime >= value) {
        int64_t result = context->prime_sum[value] - context->prime_sum[prime] + 1;
        const int32_t limit = context->prime_count[integer_sqrt(value)];
        for (int32_t index = count; index < limit; ++index) {
            const int64_t other = context->primes[index];
            result += other * (context->prime_sum[value / other] -
                               context->prime_sum[other - 1]);
        }
        return result;
    }
    return weighted_phi(context, value, count - 1) -
           prime * weighted_phi(context, value / prime, count - 1);
}

static int64_t sum_primes(prime_sum_context *context, int64_t value) {
    if (value <= SIEVE_LIMIT) return context->prime_sum[value];
    const int32_t first = context->prime_count[integer_cuberoot(value)];
    const int32_t last = context->prime_count[integer_sqrt(value)];
    int64_t result = weighted_phi(context, value, first) +
                     context->prime_sum[integer_cuberoot(value)] - 1;
    for (int32_t index = first; index < last; ++index) {
        const int64_t prime = context->primes[index];
        const int64_t quotient = value / prime;
        result -= (sum_primes(context, quotient) - context->prime_sum[prime - 1]) * prime;
    }
    return result;
}

int64_t fast_prime_sums(int64_t value) {
    if (value < 0 || value > 1000000000LL) return -1;
    prime_sum_context context = {0};
    for (int32_t candidate = 2; candidate * candidate <= SIEVE_LIMIT; ++candidate) {
        if (context.composite[candidate]) continue;
        for (int32_t multiple = candidate * candidate; multiple <= SIEVE_LIMIT;
             multiple += candidate)
            context.composite[multiple] = 1;
    }
    int32_t count = 0;
    for (int32_t candidate = 2; candidate <= SIEVE_LIMIT; ++candidate) {
        if (!context.composite[candidate]) context.primes[count++] = candidate;
        context.prime_count[candidate] = context.prime_count[candidate - 1] +
                                         !context.composite[candidate];
        context.prime_sum[candidate] = context.prime_sum[candidate - 1] +
            (context.composite[candidate] ? 0 : candidate);
    }
    for (int32_t value_index = 0; value_index < PHI_COLUMNS; ++value_index)
        context.phi[value_index] = (int64_t)value_index * (value_index + 1) / 2;
    for (int32_t row = 1; row < PHI_ROWS; ++row) {
        const int64_t prime = context.primes[row - 1];
        for (int32_t value_index = 0; value_index < PHI_COLUMNS; ++value_index) {
            const int32_t previous = (row - 1) * PHI_COLUMNS;
            context.phi[row * PHI_COLUMNS + value_index] =
                context.phi[previous + value_index] -
                prime * context.phi[previous + value_index / prime];
        }
    }
    return sum_primes(&context, value);
}
