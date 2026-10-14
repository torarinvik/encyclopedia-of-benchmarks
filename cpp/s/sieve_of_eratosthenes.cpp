/* Count the primes through limit using the Sieve of Eratosthenes. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t sieve_of_eratosthenes(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > 4096) return -1;
    bool prime[4097]{};
    for (std::int64_t value = 2; value <= limit; ++value) prime[value] = true;
    for (std::int64_t factor = 2; factor <= limit / factor; ++factor) {
        if (prime[factor]) {
            for (std::int64_t multiple = factor * factor; multiple <= limit; multiple += factor)
                prime[multiple] = false;
        }
    }
    std::int64_t count = 0;
    for (std::int64_t value = 2; value <= limit; ++value) count += prime[value];
    return count;
}
