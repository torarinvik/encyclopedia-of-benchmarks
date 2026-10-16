/* Count source-sequence prime candidates strictly below max_prime. */
#include <cstdint>

namespace {
constexpr std::int64_t max_prime_limit = 1'000'000;

bool problem131_is_prime(std::int64_t number) noexcept
{
    if (number < 2) return false;
    for (std::int64_t divisor = 2; divisor <= number / divisor; ++divisor) {
        if (number % divisor == 0) return false;
    }
    return true;
}
}

extern "C" std::int64_t problem131(std::int64_t max_prime) noexcept
{
    if (max_prime < 0 || max_prime > max_prime_limit) return -1;
    std::int64_t primes_count = 0;
    std::int64_t cube_index = 1;
    std::int64_t prime_candidate = 7;
    while (prime_candidate < max_prime) {
        primes_count += problem131_is_prime(prime_candidate);
        ++cube_index;
        prime_candidate += 6 * cube_index;
    }
    return primes_count;
}
