#include <array>
#include <cstdint>

namespace {
constexpr std::uint32_t MAX_N = 10000000;
constexpr std::size_t PRIME_LIMIT = 3162;
constexpr std::size_t PRIME_CAPACITY = 500;
constexpr std::size_t SEGMENT_SIZE = 32768;

bool same_digits(std::uint32_t left, std::uint32_t right)
{
    std::array<int, 10> counts{};
    while (left != 0) { ++counts[left % 10]; left /= 10; }
    while (right != 0) { --counts[right % 10]; right /= 10; }
    for (int count : counts) if (count != 0) return false;
    return true;
}
}

extern "C" std::int64_t problem70(std::int64_t max_n)
{
    if (max_n < 0 || max_n > MAX_N) return -1;
    const auto limit = static_cast<std::uint32_t>(max_n);
    std::array<bool, PRIME_LIMIT + 1> is_prime{};
    std::array<std::uint32_t, PRIME_CAPACITY> primes{};
    std::size_t prime_count = 0;
    for (std::uint32_t value = 2; value <= PRIME_LIMIT && value <= limit / value; ++value) is_prime[value] = true;
    for (std::uint32_t prime = 2; prime <= PRIME_LIMIT && prime <= limit / prime; ++prime) {
        if (!is_prime[prime]) continue;
        for (std::uint32_t multiple = prime * prime; multiple <= PRIME_LIMIT && multiple <= limit / multiple; multiple += prime)
            is_prime[multiple] = false;
    }
    for (std::uint32_t value = 2; value <= PRIME_LIMIT && value <= limit / value; ++value)
        if (is_prime[value]) primes[prime_count++] = value;

    std::array<std::uint32_t, SEGMENT_SIZE> phi{}, remainder{};
    std::uint32_t best_n = 1, best_phi = 0;
    for (std::uint32_t low = 0; low <= limit;) {
        std::uint32_t high = low + static_cast<std::uint32_t>(SEGMENT_SIZE) - 1;
        if (high < low || high > limit) high = limit;
        const std::uint32_t length = high - low + 1;
        for (std::uint32_t offset = 0; offset < length; ++offset) {
            phi[offset] = low + offset;
            remainder[offset] = low + offset;
        }
        for (std::size_t index = 0; index < prime_count; ++index) {
            const std::uint32_t prime = primes[index];
            std::uint32_t first = low + (prime - low % prime) % prime;
            if (first < prime) first = prime;
            for (std::uint32_t multiple = first; multiple <= high;) {
                const std::uint32_t offset = multiple - low;
                phi[offset] -= phi[offset] / prime;
                while (remainder[offset] % prime == 0) remainder[offset] /= prime;
                if (high - multiple < prime) break;
                multiple += prime;
            }
        }
        for (std::uint32_t offset = 0; offset < length; ++offset) {
            if (remainder[offset] > 1) phi[offset] -= phi[offset] / remainder[offset];
            const std::uint32_t number = low + offset;
            if (number < 2) continue;
            if (static_cast<std::uint64_t>(number) * best_phi
                    < static_cast<std::uint64_t>(best_n) * phi[offset]
                    && same_digits(number, phi[offset])) {
                best_n = number;
                best_phi = phi[offset];
            }
        }
        if (high == limit) break;
        low = high + 1;
    }
    return static_cast<std::int64_t>(best_n);
}
