/* Count primes through limit with the linear (Euler) sieve. */
#include <cstdint>

extern "C" std::int64_t linear_sieve(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > 4096) return -1;
    if (limit < 2) return 0;
    std::int64_t state[4662]{};
    for (std::int64_t value = 2; value <= limit; ++value) {
        if (state[value] == 0) {
            state[value] = value;
            state[4097 + state[4661]] = value;
            ++state[4661];
        }
        for (std::int64_t index = 0; index < state[4661]; ++index) {
            const std::int64_t prime = state[4097 + index];
            if (prime > state[value] || prime > limit / value) break;
            state[value * prime] = prime;
        }
    }
    return state[4661];
}
