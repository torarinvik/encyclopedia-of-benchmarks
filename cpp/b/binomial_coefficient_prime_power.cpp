#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_queries = 32, max_n = 128, max_parseable = 68;

bool is_prime(std::int64_t value) noexcept {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor)
        if (value % divisor == 0) return false;
    return true;
}

std::int64_t pow_mod(std::int64_t base, std::int64_t exponent,
                     std::int64_t modulus) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
}

extern "C" std::int64_t binomial_coefficient_prime_power(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_parseable) return -1;
    const auto p = input[0], e = input[1], q_value = input[2];
    if (p < 2 || p > 31 || !is_prime(p) || e < 1 || e > 8 || q_value < 0 || q_value > 32) return -1;
    std::int64_t modulus = 1;
    for (std::int64_t index = 0; index < e; ++index) {
        modulus *= p;
        if (modulus > 1000000000) return -1;
    }
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 3 + 2 * q) return -1;
    for (std::size_t i = 0; i < q; ++i) {
        const auto n = input[3 + 2 * i], k = input[4 + 2 * i];
        if (n < 0 || n > static_cast<std::int64_t>(max_n) || k < 0 || k > n) return -1;
    }
    if (q == 0) return 0;
    const auto required = 4 * q;
    if (output == nullptr || capacity < required) return -2;

    std::array<std::int64_t, max_n + 1> unit_prefix{};
    std::array<std::int64_t, max_n + 1> p_free_factorial{};
    std::array<std::uint16_t, max_n + 1> valuation{};
    std::array<std::uint32_t, max_queries> residues{};
    unit_prefix[0] = p_free_factorial[0] = 1;
    for (std::size_t n = 1; n <= max_n; ++n) {
        const auto factor = n % static_cast<std::size_t>(p) == 0 ? 1 : static_cast<std::int64_t>(n);
        unit_prefix[n] = unit_prefix[n - 1] * factor % modulus;
        p_free_factorial[n] = unit_prefix[n] * p_free_factorial[n / static_cast<std::size_t>(p)] % modulus;
        valuation[n] = static_cast<std::uint16_t>(n / static_cast<std::size_t>(p) + valuation[n / static_cast<std::size_t>(p)]);
    }
    const auto phi = modulus / p * (p - 1);
    for (std::size_t i = 0; i < q; ++i) {
        const auto n = static_cast<std::size_t>(input[3 + 2 * i]);
        const auto k = static_cast<std::size_t>(input[4 + 2 * i]);
        const auto p_power = static_cast<std::size_t>(valuation[n] - valuation[k] - valuation[n - k]);
        if (p_power >= static_cast<std::size_t>(e)) continue;
        const auto denominator = p_free_factorial[k] * p_free_factorial[n - k] % modulus;
        const auto inverse = pow_mod(denominator, phi - 1, modulus);
        const auto prime_factor = pow_mod(p, static_cast<std::int64_t>(p_power), modulus);
        residues[i] = static_cast<std::uint32_t>(p_free_factorial[n] * inverse % modulus * prime_factor % modulus);
    }
    for (std::size_t i = 0; i < q; ++i)
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[4 * i + byte] = static_cast<std::uint8_t>(residues[i] >> (8 * byte));
    return static_cast<std::int64_t>(required);
}
