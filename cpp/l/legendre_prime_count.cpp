#include <cstdint>

namespace {
constexpr std::int64_t max_input = 10000;

std::int64_t legendre_phi(const std::int64_t* primes, std::int64_t value, std::int64_t count) noexcept
{
    if (value == 0) return 0;
    if (count == 0) return value;
    if (count == 1) return value - value / 2;
    const auto prime = primes[count - 1];
    if (value < prime) return 1;
    return legendre_phi(primes, value, count - 1) -
        legendre_phi(primes, value / prime, count - 1);
}
}

extern "C" std::int64_t legendre_prime_count(std::int64_t value) noexcept
{
    if (value < 0 || value > max_input) return -1;
    if (value < 2) return 0;
    std::int64_t root = 0;
    while ((root + 1) * (root + 1) <= value) ++root;
    bool composite[101]{};
    for (std::int64_t candidate = 2; candidate * candidate <= root; ++candidate) {
        if (composite[candidate]) continue;
        for (std::int64_t multiple = candidate * candidate; multiple <= root; multiple += candidate)
            composite[multiple] = true;
    }
    std::int64_t primes[25];
    std::int64_t count = 0;
    for (std::int64_t candidate = 2; candidate <= root; ++candidate)
        if (!composite[candidate]) primes[count++] = candidate;
    return legendre_phi(primes, value, count) + count - 1;
}
