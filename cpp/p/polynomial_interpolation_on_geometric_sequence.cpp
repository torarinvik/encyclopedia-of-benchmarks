#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 8;
constexpr std::size_t max_input = 11;

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

extern "C" std::int64_t polynomial_interpolation_on_geometric_sequence(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto a = input[1], r = input[2];
    if (length != 3 + n || a < 0 || a >= modulus || r < 0 || r >= modulus) return -1;

    std::array<std::int64_t, max_n> points{};
    std::array<std::int64_t, max_n> differences{};
    std::array<std::int64_t, max_n> newton{};
    auto point = a;
    for (std::size_t i = 0; i < n; ++i) {
        points[i] = point;
        differences[i] = input[3 + i];
        if (differences[i] < 0 || differences[i] >= modulus) return -1;
        for (std::size_t j = 0; j < i; ++j) if (points[i] == points[j]) return -1;
        point = point * r % modulus;
    }

    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;
    if (n == 0) return 0;
    newton[0] = differences[0];
    for (std::size_t order = 1; order < n; ++order) {
        const auto r_order = power_mod(r, static_cast<std::int64_t>(order));
        for (std::size_t end = n; end > order; --end) {
            const auto i = end - 1;
            const auto r_factor = power_mod(r, static_cast<std::int64_t>(i - order));
            auto denominator = a * r_factor % modulus;
            denominator = denominator * (r_order - 1) % modulus;
            const auto inverse = power_mod(normalize(denominator), modulus - 2);
            differences[i] = normalize((differences[i] - differences[i - 1]) * inverse);
        }
        newton[order] = differences[order];
    }

    std::array<std::int64_t, max_n> coefficients{};
    std::array<std::int64_t, max_n + 1> basis{};
    basis[0] = 1;
    std::size_t degree = 0;
    for (std::size_t order = 0; order < n; ++order) {
        for (std::size_t k = 0; k <= degree; ++k)
            coefficients[k] = (coefficients[k] + newton[order] * basis[k]) % modulus;
        if (order + 1 == n) break;
        std::array<std::int64_t, max_n + 1> expanded{};
        for (std::size_t k = 0; k <= degree; ++k) {
            expanded[k] = normalize(expanded[k] - basis[k] * points[order]);
            expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
        }
        for (std::size_t k = 0; k <= degree + 1; ++k) basis[k] = expanded[k];
        ++degree;
    }
    for (std::size_t i = 0; i < n; ++i) store_le(output, 8 * i, coefficients[i]);
    return static_cast<std::int64_t>(bytes);
}
