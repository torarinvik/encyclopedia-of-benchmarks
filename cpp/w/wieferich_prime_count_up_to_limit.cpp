#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 5000;
constexpr std::size_t max_parseable_length = 2;

std::int64_t modular_power(std::int64_t base, std::int64_t exponent,
                           std::int64_t modulus) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

std::int64_t count_wieferich_primes(std::int64_t limit) noexcept {
    std::array<std::uint8_t, max_limit + 1> prime{};
    for (std::int64_t n = 0; n <= limit; ++n) prime[static_cast<std::size_t>(n)] = 1;
    prime[0] = 0;
    prime[1] = 0;
    for (std::int64_t divisor = 2; divisor <= limit / divisor; ++divisor) {
        if (prime[static_cast<std::size_t>(divisor)] == 0) continue;
        for (std::int64_t multiple = divisor * divisor; multiple <= limit; multiple += divisor)
            prime[static_cast<std::size_t>(multiple)] = 0;
    }
    std::int64_t count = 0;
    for (std::int64_t p = 3; p <= limit; p += 2) {
        if (prime[static_cast<std::size_t>(p)] != 0 && modular_power(2, p - 1, p * p) == 1) ++count;
    }
    return count;
}
}

extern "C" std::int64_t wieferich_prime_count_up_to_limit(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1 || input[0] < 2 || input[0] > max_limit) return -1;
    return count_wieferich_primes(input[0]);
}
