// Prime-exponent factorial using binary buckets and balanced powers.
#include <array>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 20;
constexpr std::size_t max_buckets = 8;

std::int64_t exponent_in_factorial(std::int64_t prime, std::int64_t n) {
    std::int64_t exponent = 0;
    for (std::int64_t quotient = n / prime; quotient > 0; quotient /= prime) exponent += quotient;
    return exponent;
}

std::int64_t power_by_squaring(std::int64_t base, std::uint32_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1u) != 0) result *= base;
        exponent >>= 1;
        if (exponent > 0) base *= base;
    }
    return result;
}
}

extern "C" std::int64_t fast_factorial(std::int64_t n) noexcept {
    if (n < 0 || n > max_n) return -1;
    if (n < 2) return 1;

    std::array<bool, max_n + 1> is_prime{};
    for (std::int64_t candidate = 2; candidate <= n; ++candidate) is_prime[candidate] = true;
    for (std::int64_t prime = 2; prime * prime <= n; ++prime) {
        if (!is_prime[prime]) continue;
        for (std::int64_t multiple = prime * prime; multiple <= n; multiple += prime)
            is_prime[multiple] = false;
    }

    const std::int64_t exponent_of_two = exponent_in_factorial(2, n);
    std::int64_t next_power_of_two = 1;
    std::uint32_t power_log2 = 0;
    while (next_power_of_two < exponent_of_two) {
        next_power_of_two <<= 1;
        ++power_log2;
    }
    const std::uint32_t bucket_count = power_log2 + 1;
    std::array<std::int64_t, max_buckets> buckets{};
    buckets.fill(1);

    for (std::int64_t prime = 2; prime <= n; ++prime) {
        if (!is_prime[prime]) continue;
        const auto exponent_bits = static_cast<std::uint32_t>(exponent_in_factorial(prime, n));
        for (std::uint32_t bit = 0; bit < bucket_count; ++bit) {
            if ((exponent_bits & (1u << bit)) != 0) buckets[bit] *= prime;
        }
    }

    std::int64_t result = 1;
    for (std::uint32_t bit = 0; bit < bucket_count; ++bit)
        result *= power_by_squaring(buckets[bit], 1u << bit);
    return result;
}
