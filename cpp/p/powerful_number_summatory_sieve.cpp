#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_sieve_limit = 1000;

struct PowerfulSieveState {
    std::int64_t n;
    std::int64_t primes[max_sieve_limit + 1];
    std::size_t prime_count;
    std::int64_t total;
};

void enumerate_powerful(PowerfulSieveState &state, std::size_t start,
                        std::int64_t current, std::int64_t current_h)
{
    const std::int64_t remaining = state.n / current;
    for (std::size_t index = start; index < state.prime_count; ++index) {
        const std::int64_t prime = state.primes[index];
        if (prime > remaining / prime) break;

        std::int64_t prime_power = prime * prime;
        std::int64_t h_power = prime - 1;
        while (prime_power <= remaining) {
            const std::int64_t powerful = current * prime_power;
            const std::int64_t h_value = current_h * h_power;
            state.total += h_value * (state.n / powerful);
            enumerate_powerful(state, index + 1, powerful, h_value);

            if (prime_power > remaining / prime) break;
            prime_power *= prime;
            h_power *= prime;
        }
    }
}
}

extern "C" std::int64_t powerful_number_summatory_sieve(
    const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 1) return -1;
    const std::int64_t n = input[0];
    if (n < 1 || n > 1'000'000) return -1;

    std::size_t prime_limit = 0;
    while (static_cast<std::int64_t>(prime_limit + 1)
        * static_cast<std::int64_t>(prime_limit + 1) <= n) ++prime_limit;

    bool is_prime[max_sieve_limit + 1]{};
    for (std::size_t value = 0; value <= prime_limit; ++value) is_prime[value] = true;
    is_prime[0] = false;
    if (prime_limit >= 1) is_prime[1] = false;
    for (std::size_t prime = 2; prime * prime <= prime_limit; ++prime) {
        if (!is_prime[prime]) continue;
        for (std::size_t composite = prime * prime; composite <= prime_limit; composite += prime)
            is_prime[composite] = false;
    }

    PowerfulSieveState state{};
    state.n = n;
    state.total = n;
    for (std::size_t value = 2; value <= prime_limit; ++value) {
        if (is_prime[value]) state.primes[state.prime_count++] = static_cast<std::int64_t>(value);
    }
    enumerate_powerful(state, 0, 1, 1);
    return state.total;
}
