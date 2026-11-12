#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_factors = 6;
constexpr std::size_t max_coefficients = 25;
constexpr std::size_t max_input = 38;

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t product_of_polynomial_sequence(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_factors)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    std::array<std::int64_t, max_factors * max_coefficients> polynomials{};
    std::array<std::size_t, max_factors> lengths{};
    std::size_t cursor = 1;
    std::size_t degree_sum = 0;
    for (std::size_t p = 0; p < count; ++p) {
        if (cursor >= length || input[cursor] < 0 || input[cursor] > 4) return -1;
        const auto degree = static_cast<std::size_t>(input[cursor++]);
        if (cursor + degree + 1 > length) return -1;
        for (std::size_t i = 0; i <= degree; ++i) {
            const auto coefficient = input[cursor + i];
            if (coefficient < 0 || coefficient >= modulus) return -1;
            polynomials[p * max_coefficients + i] = coefficient;
        }
        if (polynomials[p * max_coefficients + degree] == 0) return -1;
        lengths[p] = degree + 1;
        degree_sum += degree;
        cursor += degree + 1;
    }
    if (cursor != length) return -1;

    const auto result_length = degree_sum + 1;
    const auto bytes = 8 * result_length;
    if (output == nullptr || capacity < bytes) return -2;
    if (count == 0) {
        store_le(output, 0, 1);
        return 8;
    }

    std::array<std::int64_t, max_coefficients> scratch{};
    auto active = count;
    while (active > 1) {
        std::size_t next_count = 0;
        for (std::size_t i = 0; i < active; i += 2) {
            const auto destination = next_count * max_coefficients;
            if (i + 1 == active) {
                const auto source = i * max_coefficients;
                for (std::size_t j = 0; j < lengths[i]; ++j)
                    polynomials[destination + j] = polynomials[source + j];
                lengths[next_count] = lengths[i];
            } else {
                const auto left_start = i * max_coefficients;
                const auto right_start = (i + 1) * max_coefficients;
                const auto product_length = lengths[i] + lengths[i + 1] - 1;
                for (std::size_t j = 0; j < product_length; ++j) scratch[j] = 0;
                for (std::size_t a = 0; a < lengths[i]; ++a) {
                    for (std::size_t b = 0; b < lengths[i + 1]; ++b) {
                        const auto slot = a + b;
                        scratch[slot] = (scratch[slot] +
                            polynomials[left_start + a] * polynomials[right_start + b]) % modulus;
                    }
                }
                for (std::size_t j = 0; j < product_length; ++j)
                    polynomials[destination + j] = scratch[j];
                lengths[next_count] = product_length;
            }
            ++next_count;
        }
        active = next_count;
    }
    for (std::size_t i = 0; i < result_length; ++i)
        store_le(output, 8 * i, polynomials[i]);
    return static_cast<std::int64_t>(bytes);
}
