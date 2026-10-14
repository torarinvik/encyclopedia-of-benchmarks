/* Count primes through limit with the linear (Euler) sieve. */
#include <stdint.h>

#define MAX_LIMIT INT64_C(4096)
#define PRIME_OFFSET 4097
#define COUNT_INDEX 4661
#define STATE_SIZE 4662

int64_t linear_sieve(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    if (limit < 2) return 0;
    int64_t state[STATE_SIZE] = {0};
    for (int64_t value = 2; value <= limit; ++value) {
        if (state[value] == 0) {
            state[value] = value;
            state[PRIME_OFFSET + state[COUNT_INDEX]] = value;
            ++state[COUNT_INDEX];
        }
        for (int64_t index = 0; index < state[COUNT_INDEX]; ++index) {
            const int64_t prime = state[PRIME_OFFSET + index];
            if (prime > state[value] || prime > limit / value) break;
            state[value * prime] = prime;
        }
    }
    return state[COUNT_INDEX];
}
