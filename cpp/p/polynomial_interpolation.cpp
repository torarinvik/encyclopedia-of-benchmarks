#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 12;
constexpr std::size_t max_input = 25;

std::int64_t normalize(std::int64_t value) {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

std::int64_t power_mod(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t polynomial_interpolation(const std::int64_t* input,
                                                  std::size_t length,
                                                  std::uint8_t* output,
                                                  std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    const auto* xs = input + 1;
    const auto* ys = input + 1 + n;
    for (std::size_t i = 0; i < n; ++i) {
        if (xs[i] < 0 || xs[i] >= modulus || ys[i] < 0 || ys[i] >= modulus) return -1;
        for (std::size_t j = 0; j < i; ++j) if (xs[i] == xs[j]) return -1;
    }

    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::int64_t, max_n> result{};
    for (std::size_t i = 0; i < n; ++i) {
        std::array<std::int64_t, max_n + 1> basis{};
        basis[0] = 1;
        std::size_t degree = 0;
        std::int64_t denominator = 1;
        for (std::size_t j = 0; j < n; ++j) {
            if (j == i) continue;
            denominator = denominator * (xs[i] - xs[j]) % modulus;
            std::array<std::int64_t, max_n + 1> expanded{};
            for (std::size_t k = 0; k <= degree; ++k) {
                expanded[k] = normalize(expanded[k] - basis[k] * xs[j]);
                expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
            }
            for (std::size_t k = 0; k <= degree + 1; ++k) basis[k] = expanded[k];
            ++degree;
        }
        const auto scale = ys[i] * power_mod(normalize(denominator), modulus - 2) % modulus;
        for (std::size_t k = 0; k < n; ++k)
            result[k] = (result[k] + scale * basis[k]) % modulus;
    }
    for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(bytes);
}
