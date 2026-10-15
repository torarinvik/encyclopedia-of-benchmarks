#include <cstdint>

namespace {
constexpr std::int64_t max_index = 999;
constexpr std::int64_t max_primes = 168;
}

extern "C" std::int64_t prime_pi_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index > max_index) return -1;
    const std::int64_t target = index + 1;
    std::int64_t primes[max_primes];
    std::int64_t prime_count = 0;
    if (target >= 2) primes[prime_count++] = 2;
    for (std::int64_t candidate = 3; candidate <= target; candidate += 2) {
        bool is_prime = true;
        for (std::int64_t i = 0; i < prime_count; ++i) {
            if (candidate % primes[i] == 0) {
                is_prime = false;
                break;
            }
        }
        if (is_prime) primes[prime_count++] = candidate;
    }
    return prime_count;
}
