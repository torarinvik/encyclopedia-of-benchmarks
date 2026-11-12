#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input = 66;

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

std::int64_t mod_sqrt(std::int64_t value)
{
    if (value == 0) return 0;
    if (mod_pow(value, (modulus - 1) / 2) != 1) return -1;
    auto odd_part = modulus - 1;
    std::size_t twos = 0;
    while (odd_part % 2 == 0) { odd_part /= 2; ++twos; }
    std::int64_t non_residue = 2;
    while (mod_pow(non_residue, (modulus - 1) / 2) != modulus - 1) ++non_residue;
    auto c = mod_pow(non_residue, odd_part);
    auto root = mod_pow(value, (odd_part + 1) / 2);
    auto remainder = mod_pow(value, odd_part);
    auto order = twos;
    while (remainder != 1) {
        std::size_t index = 1;
        auto probe = remainder * remainder % modulus;
        while (index < order && probe != 1) { probe = probe * probe % modulus; ++index; }
        if (index >= order || probe != 1) return -1;
        std::int64_t exponent = 1;
        for (std::size_t bit = 0; bit < order - index - 1; ++bit) exponent *= 2;
        auto factor = mod_pow(c, exponent);
        root = root * factor % modulus;
        auto factor_squared = factor * factor % modulus;
        remainder = remainder * factor_squared % modulus;
        c = factor_squared;
        order = index;
    }
    return root < modulus - root ? root : modulus - root;
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

extern "C" std::int64_t sqrt_of_formal_power_series(const std::int64_t* input,
                                                     std::size_t length,
                                                     std::uint8_t* output,
                                                     std::size_t capacity)
{
    if (input == nullptr || length < 2 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;
    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;

    std::array<std::int64_t, max_n> result{};
    std::size_t valuation = 0;
    while (valuation < n && input[valuation + 1] == 0) ++valuation;
    if (valuation == n) {
        for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, 0);
        return static_cast<std::int64_t>(bytes);
    }
    if (valuation % 2 != 0) { store_le(output, 0, -1); return 8; }
    const auto shift = valuation / 2;
    const auto leading_root = mod_sqrt(input[valuation + 1]);
    if (leading_root < 0) { store_le(output, 0, -1); return 8; }
    const auto inverse_twice_root = mod_pow(2 * leading_root % modulus, modulus - 2);
    const auto width = n - valuation;
    result[shift] = leading_root;
    for (std::size_t degree = 1; degree < width; ++degree) {
        std::int64_t cross_terms = 0;
        for (std::size_t i = 1; i < degree; ++i)
            cross_terms = (cross_terms + result[shift + i] * result[shift + degree - i]) % modulus;
        auto delta = (input[valuation + degree + 1] - cross_terms) % modulus;
        if (delta < 0) delta += modulus;
        result[shift + degree] = delta * inverse_twice_root % modulus;
    }
    for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(bytes);
}
