#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 999966663333LL;
constexpr int sieve_cap = 1000100;
constexpr int prime_cap = 80000;
}

extern "C" std::int64_t problem234(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > max_limit) return -1;
    std::uint8_t composite[sieve_cap]{};
    std::int64_t primes[prime_cap];
    int prime_count = 0;
    std::int64_t root = 0;
    while (root + 1 <= limit / (root + 1)) ++root;
    const int sieve_end = static_cast<int>(root) + 100;
    for (int p = 2; p < sieve_end; ++p) {
        if (composite[p]) continue;
        primes[prime_count++] = p;
        if (static_cast<std::int64_t>(p) * p < sieve_end)
            for (int multiple = p * p; multiple < sieve_end; multiple += p) composite[multiple] = 1;
    }
    std::int64_t total = 0;
    int index = 0;
    auto p = primes[index];
    while (p * p <= limit) {
        const auto q = primes[index + 1];
        const auto lower = p * p;
        auto upper = q * q;
        auto current = lower + p;
        while (upper > current && current <= limit) { total += current; current += p; }
        while (upper - q > limit) upper -= q;
        current = upper - q;
        while (current > lower) { total += current; current -= q; }
        current = 0;
        while (upper > current && current <= limit) {
            if (current <= lower) { current += p * q; continue; }
            if (current > limit) break;
            total -= current * 2;
            current += p * q;
        }
        p = q;
        ++index;
    }
    return total;
}
