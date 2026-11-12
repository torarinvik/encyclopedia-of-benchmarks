#include <array>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 1'000'000'000;
constexpr std::int64_t base_limit = 100'000;
constexpr std::size_t max_cache = static_cast<std::size_t>(max_n / base_limit + 2);
constexpr std::int64_t modulus = 998'244'353;

std::int64_t triangular_mod(std::int64_t n) noexcept {
    auto left = n;
    auto right = n + 1;
    if ((left & 1) == 0) left /= 2;
    else right /= 2;
    return ((left % modulus) * (right % modulus)) % modulus;
}

std::int64_t summatory_phi(std::int64_t value, std::int64_t total_n,
                           const std::array<std::int64_t, base_limit + 1>& prefix,
                           std::array<std::int64_t, max_cache>& memo,
                           std::array<std::uint8_t, max_cache>& visited) {
    if (value <= base_limit) return prefix[static_cast<std::size_t>(value)];
    const auto cache_index = static_cast<std::size_t>(total_n / value);
    if (visited[cache_index] != 0) return memo[cache_index];

    auto answer = triangular_mod(value);
    for (std::int64_t left = 2; left <= value;) {
        const auto quotient = value / left;
        const auto right = value / quotient;
        const auto block_size = right - left + 1;
        const auto sub_sum = summatory_phi(quotient, total_n, prefix, memo, visited);
        const auto contribution = ((block_size % modulus) * sub_sum) % modulus;
        answer = (answer - contribution + modulus) % modulus;
        left = right + 1;
    }
    visited[cache_index] = 1;
    memo[cache_index] = answer;
    return answer;
}
} // namespace

extern "C" std::int64_t sum_of_totient_function(std::int64_t n) noexcept {
    if (n < 1 || n > max_n) return -1;
    std::array<std::int64_t, base_limit + 1> prefix{};
    for (std::int64_t value = 0; value <= base_limit; ++value)
        prefix[static_cast<std::size_t>(value)] = value;
    const auto sieve_limit = n < base_limit ? n : base_limit;
    for (std::int64_t prime = 2; prime <= sieve_limit; ++prime) {
        if (prefix[static_cast<std::size_t>(prime)] != prime) continue;
        for (auto multiple = prime; multiple <= sieve_limit; multiple += prime) {
            auto& value = prefix[static_cast<std::size_t>(multiple)];
            value -= value / prime;
        }
    }
    std::int64_t running = 0;
    for (std::int64_t value = 1; value <= sieve_limit; ++value) {
        running = (running + prefix[static_cast<std::size_t>(value)]) % modulus;
        prefix[static_cast<std::size_t>(value)] = running;
    }
    if (n <= base_limit) return prefix[static_cast<std::size_t>(n)];

    std::array<std::int64_t, max_cache> memo{};
    std::array<std::uint8_t, max_cache> visited{};
    return summatory_phi(n, n, prefix, memo, visited);
}
