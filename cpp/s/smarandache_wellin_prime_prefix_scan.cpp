#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_count = 6;

bool is_small_prime(std::uint64_t value) {
    if (value < 2) return false;
    for (std::uint64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}

std::uint64_t multiply_mod(std::uint64_t left, std::uint64_t right,
                           std::uint64_t modulus) noexcept {
    return (left * right) % modulus;
}

std::uint64_t power_mod(std::uint64_t base, std::uint64_t exponent,
                        std::uint64_t modulus) noexcept {
    std::uint64_t result = 1;
    base %= modulus;
    while (exponent != 0) {
        if ((exponent & 1U) != 0) result = multiply_mod(result, base, modulus);
        exponent >>= 1U;
        if (exponent != 0) base = multiply_mod(base, base, modulus);
    }
    return result;
}

bool is_prime_prefix(std::uint64_t value) noexcept {
    constexpr std::array<std::uint32_t, 12> small_primes{
        2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37};
    constexpr std::array<std::uint32_t, 3> bases{2, 7, 61};
    if (value < 2) return false;
    for (const auto prime : small_primes) {
        if (value == prime) return true;
        if (value % prime == 0) return false;
    }
    auto odd_part = value - 1;
    unsigned twos = 0;
    while ((odd_part & 1U) == 0) {
        odd_part >>= 1U;
        ++twos;
    }
    for (const auto base : bases) {
        auto witness = power_mod(base, odd_part, value);
        if (witness == 1 || witness == value - 1) continue;
        unsigned round = 1;
        while (round < twos && witness != value - 1) {
            witness = multiply_mod(witness, witness, value);
            ++round;
        }
        if (witness != value - 1) return false;
    }
    return true;
}
}  // namespace

extern "C" std::int64_t smarandache_wellin_prime_prefix_scan(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > 2) return -1;
    if (input[0] < 0 || input[0] > max_count || length != 1) return -1;

    std::array<std::uint64_t, 3> values{};
    std::size_t result_count = 0;
    std::uint64_t prefix = 0;
    std::uint64_t candidate = 2;
    for (std::int64_t index = 0; index < input[0]; ++index) {
        while (!is_small_prime(candidate)) candidate += candidate == 2 ? 1 : 2;
        std::uint64_t scale = 10;
        while (scale <= candidate) scale *= 10;
        prefix = prefix * scale + candidate;
        if (is_prime_prefix(prefix)) values[result_count++] = prefix;
        candidate += candidate == 2 ? 1 : 2;
    }

    const auto byte_count = result_count * 8;
    if (output == nullptr || capacity < byte_count) return -2;
    std::array<std::uint8_t, 24> staged{};
    for (std::size_t item = 0; item < result_count; ++item) {
        for (std::size_t byte = 0; byte < 8; ++byte) {
            staged[item * 8 + byte] = static_cast<std::uint8_t>(values[item] >> (8 * byte));
        }
    }
    for (std::size_t byte = 0; byte < byte_count; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(byte_count);
}
