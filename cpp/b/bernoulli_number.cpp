#include <cstddef>
#include <cstdint>

namespace {
std::int64_t modular_power(std::int64_t base, std::int64_t exponent) noexcept {
    constexpr std::int64_t modulus = 998244353;
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
} // namespace

extern "C" std::int64_t bernoulli_number(const std::int64_t *input,
                                          std::size_t length,
                                          std::uint8_t *output,
                                          std::size_t capacity) noexcept {
    constexpr std::int64_t modulus = 998244353;
    constexpr std::size_t max_n = 32;
    if (input == nullptr || length != 1) return -1;
    const auto n64 = input[0];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto output_bytes = 4 * (n + 1);
    if (output == nullptr || capacity < output_bytes) return -2;

    std::int64_t inverse[max_n + 2]{};
    std::int64_t bernoulli[max_n + 1]{};
    inverse[1] = 1;
    for (std::size_t i = 2; i <= n + 1; ++i) {
        inverse[i] = modular_power(static_cast<std::int64_t>(i), modulus - 2);
    }

    bernoulli[0] = 1;
    for (std::size_t m = 1; m <= n; ++m) {
        std::int64_t choose = 1, sum = 0;
        for (std::size_t k = 0; k < m; ++k) {
            sum = (sum + choose * bernoulli[k]) % modulus;
            choose = choose * static_cast<std::int64_t>(m + 1 - k) % modulus *
                inverse[k + 1] % modulus;
        }
        bernoulli[m] = ((modulus - sum) % modulus) * inverse[m + 1] % modulus;
    }

    for (std::size_t i = 0; i <= n; ++i) {
        const auto value = static_cast<std::uint32_t>(bernoulli[i]);
        output[4 * i] = static_cast<std::uint8_t>(value);
        output[4 * i + 1] = static_cast<std::uint8_t>(value >> 8);
        output[4 * i + 2] = static_cast<std::uint8_t>(value >> 16);
        output[4 * i + 3] = static_cast<std::uint8_t>(value >> 24);
    }
    return static_cast<std::int64_t>(output_bytes);
}
