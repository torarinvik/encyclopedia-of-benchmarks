// Count primes through limit with Sundaram's index sieve.
#include <cstdint>

extern "C" std::int64_t sieve_of_sundaram(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > 4096) return -1;
    if (limit < 2) return 0;

    const std::int64_t max_index = (limit - 1) / 2;
    bool composite[2048]{};
    for (std::int64_t i = 1; 2 * i * (i + 1) <= max_index; ++i) {
        for (std::int64_t j = i; ; ++j) {
            const auto index = i + j + 2 * i * j;
            if (index > max_index) break;
            composite[index] = true;
        }
    }
    std::int64_t count = 1;
    for (std::int64_t index = 1; index <= max_index; ++index)
        count += !composite[index];
    return count;
}
