#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 12;
constexpr std::size_t max_input = 25;

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t conversion_from_monomial_basis_to_newton_basis(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    for (std::size_t i = 0; i < 2 * n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;

    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::int64_t, max_n> residual{};
    std::array<std::int64_t, max_n> answer{};
    for (std::size_t i = 0; i < n; ++i) residual[i] = input[i + 1];

    auto active = n;
    for (std::size_t i = 0; i < n; ++i) {
        const auto node = input[n + 1 + i];
        std::int64_t value = 0;
        for (auto degree = active; degree > 0; --degree)
            value = (value * node + residual[degree - 1]) % modulus;
        answer[i] = value;
        if (active == 1) continue;

        std::array<std::int64_t, max_n> quotient{};
        quotient[active - 2] = residual[active - 1];
        for (auto degree = active - 2; degree > 0; --degree)
            quotient[degree - 1] = (residual[degree] + node * quotient[degree]) % modulus;
        for (std::size_t degree = 0; degree + 1 < active; ++degree)
            residual[degree] = quotient[degree];
        --active;
    }
    for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, answer[i]);
    return static_cast<std::int64_t>(bytes);
}
