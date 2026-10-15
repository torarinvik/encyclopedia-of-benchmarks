// Generate zero-based prime terms using divisibility by all earlier primes.
#include <cstdint>

extern "C" std::int64_t primes_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index > 99) return -1;
    std::int64_t primes[100] = {2};
    std::int64_t count = 1;
    std::int64_t candidate = 3;
    while (count <= index) {
        bool is_prime = true;
        for (std::int64_t i = 0; i < count; ++i) {
            if (candidate % primes[i] == 0) {
                is_prime = false;
                break;
            }
        }
        if (is_prime) primes[count++] = candidate;
        candidate += 2;
    }
    return primes[index];
}
