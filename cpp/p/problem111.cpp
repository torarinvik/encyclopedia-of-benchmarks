#include <cstdint>

namespace {
constexpr std::int64_t max_n = 10000000000LL;
constexpr int sieve_cap = 100002;
constexpr int prime_cap = 100001;
bool is_prime(std::int64_t value, const std::int64_t *primes, int count) noexcept {
    for (int i = 0; i < count; ++i) { const auto p = primes[i]; if (value % p == 0) return false; }
    return true;
}
}

extern "C" std::int64_t problem111(std::int64_t n) noexcept
{
    if (n < 1000 || n > max_n) return -1;
    std::int64_t composite[sieve_cap]{};
    std::int64_t primes[prime_cap];
    int prime_count = 0;
    std::int64_t root = 0; while (root + 1 <= n / (root + 1)) ++root;
    const int sieve_limit = static_cast<int>(root) + 1;
    for (int p = 2; p <= sieve_limit; ++p) {
        if (composite[p]) continue;
        primes[prime_count++] = p;
        if (static_cast<std::int64_t>(p) * p <= sieve_limit)
            for (int multiple = p * p; multiple <= sieve_limit; multiple += p) composite[multiple] = 1;
    }
    int digits = 0; for (auto copy = n; copy > 0; copy /= 10) ++digits;
    const int width = digits - 1, repeated_two = width - 2;
    std::int64_t total = 0;
    for (int i = 1; i <= 9; ++i) for (int j = 1; j <= 9; ++j) {
        auto value = static_cast<std::int64_t>(i); for (int z = 0; z < width - 2; ++z) value *= 10; value = value * 10 + j;
        if (is_prime(value, primes, prime_count)) total += value;
    }
    bool one_digit[10]{};
    for (int i = 1; i <= 9; ++i) for (int j = 0; j < width; ++j) for (int k = 0; k <= 9; ++k) {
        std::int64_t value = 0; for (int pos = 0; pos < width; ++pos) value = value * 10 + (pos == j ? k : i);
        if (is_prime(value, primes, prime_count)) { one_digit[i] = true; total += value; }
    }
    for (int i = 1; i <= 9; ++i) if (!one_digit[i])
        for (int j = 0; j <= repeated_two; ++j) for (int k = 0; k <= repeated_two - j; ++k)
            for (int m1 = 0; m1 <= 9; ++m1) {
                if (m1 == 0 && j == 0) continue;
                for (int m2 = 0; m2 <= 9; ++m2) {
                    std::int64_t value = 0;
                    for (int pos = 0; pos < width; ++pos) value = value * 10 + (pos == j ? m1 : (pos == j + k + 1 ? m2 : i));
                    if (is_prime(value, primes, prime_count)) total += value;
                }
            }
    return total;
}
