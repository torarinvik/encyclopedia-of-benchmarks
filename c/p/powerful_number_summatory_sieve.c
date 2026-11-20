#include <stddef.h>
#include <stdint.h>

enum { MAX_SIEVE_LIMIT = 1000 };

typedef struct {
    int64_t n;
    int64_t primes[MAX_SIEVE_LIMIT + 1];
    size_t prime_count;
    int64_t total;
} PowerfulSieveState;

static void enumerate_powerful(PowerfulSieveState *state, size_t start,
                               int64_t current, int64_t current_h)
{
    const int64_t remaining = state->n / current;
    for (size_t index = start; index < state->prime_count; ++index) {
        const int64_t prime = state->primes[index];
        if (prime > remaining / prime) break;

        int64_t prime_power = prime * prime;
        int64_t h_power = prime - 1;
        while (prime_power <= remaining) {
            const int64_t powerful = current * prime_power;
            const int64_t h_value = current_h * h_power;
            state->total += h_value * (state->n / powerful);
            enumerate_powerful(state, index + 1, powerful, h_value);

            if (prime_power > remaining / prime) break;
            prime_power *= prime;
            h_power *= prime;
        }
    }
}

int64_t powerful_number_summatory_sieve(const int64_t *input, size_t length)
{
    if (input == NULL || length != 1) return -1;
    const int64_t n = input[0];
    if (n < 1 || n > 1000000) return -1;

    size_t prime_limit = 0;
    while ((int64_t)(prime_limit + 1) * (int64_t)(prime_limit + 1) <= n)
        ++prime_limit;

    uint8_t is_prime[MAX_SIEVE_LIMIT + 1] = {0};
    for (size_t value = 0; value <= prime_limit; ++value) is_prime[value] = 1;
    is_prime[0] = 0;
    if (prime_limit >= 1) is_prime[1] = 0;
    for (size_t prime = 2; prime * prime <= prime_limit; ++prime) {
        if (!is_prime[prime]) continue;
        for (size_t composite = prime * prime; composite <= prime_limit; composite += prime)
            is_prime[composite] = 0;
    }

    PowerfulSieveState state = {0};
    state.n = n;
    state.total = n;
    for (size_t value = 2; value <= prime_limit; ++value) {
        if (is_prime[value]) state.primes[state.prime_count++] = (int64_t)value;
    }
    enumerate_powerful(&state, 0, 1, 1);
    return state.total;
}
