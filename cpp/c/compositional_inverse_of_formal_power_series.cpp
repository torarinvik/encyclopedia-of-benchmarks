#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t min_n = 2;
constexpr std::size_t max_n = 16;
constexpr std::size_t max_input = 18;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent)
{
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent /= 2;
    }
    return result;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t compositional_inverse_of_formal_power_series(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity)
{
    if (input == nullptr || length < min_n + 1 || length > max_input) return -1;
    if (input[0] < static_cast<std::int64_t>(min_n) || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;
    if (input[1] != 0 || input[2] == 0) return -1;
    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;

    std::array<std::int64_t, max_n * max_n> powers{};
    std::array<std::int64_t, max_n> inverse_series{};
    const auto inverse_linear = mod_pow(input[2], modulus - 2);
    inverse_series[1] = inverse_linear;
    powers[max_n + 1] = inverse_linear;
    for (std::size_t degree = 2; degree < n; ++degree) {
        for (std::size_t power = 2; power <= degree; ++power) {
            std::int64_t coefficient = 0;
            for (std::size_t split = 1; split < degree; ++split)
                coefficient = (coefficient + powers[(power - 1) * max_n + degree - split] * inverse_series[split]) % modulus;
            powers[power * max_n + degree] = coefficient;
        }
        std::int64_t composed_coefficient = 0;
        for (std::size_t power = 2; power <= degree; ++power)
            composed_coefficient = (composed_coefficient + input[power + 1] * powers[power * max_n + degree]) % modulus;
        inverse_series[degree] = (modulus - composed_coefficient) * inverse_linear % modulus;
        powers[max_n + degree] = inverse_series[degree];
    }
    for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, inverse_series[i]);
    return static_cast<std::int64_t>(bytes);
}
