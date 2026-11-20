/* Bounded normalized Padé coefficient solve over F_998244353. */
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_input_length = 12;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) {
        output[offset + i] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t pade_approximant_series_coefficients(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > max_input_length) return -1;
    const auto p_value = input[0], q_value = input[1];
    if (q_value < 1 || p_value < q_value || p_value > 4 || q_value > 4 ||
        length != static_cast<std::size_t>(p_value + q_value + 3)) return -1;
    const auto p = static_cast<std::size_t>(p_value), q = static_cast<std::size_t>(q_value);
    std::array<std::uint32_t, 9> coefficients{};
    for (std::size_t i = 0; i <= p + q; ++i) {
        if (input[i + 2] < 0 || input[i + 2] >= modulus) return -1;
        coefficients[i] = static_cast<std::uint32_t>(input[i + 2]);
    }
    const std::size_t required = 8 * (p + q + 4);
    if (output == nullptr || capacity < required) return -2;

    std::array<std::array<std::uint32_t, 5>, 4> matrix{};
    for (std::size_t row = 0; row < q; ++row) {
        const auto m = p + 1 + row;
        for (std::size_t col = 0; col < q; ++col) matrix[row][col] = coefficients[m - col - 1];
        matrix[row][q] = static_cast<std::uint32_t>((modulus - coefficients[m]) % modulus);
    }
    for (std::size_t col = 0; col < q; ++col) {
        std::size_t pivot = col;
        while (pivot < q && matrix[pivot][col] == 0) ++pivot;
        if (pivot == q) return -3;
        if (pivot != col) std::swap(matrix[pivot], matrix[col]);
        const auto inverse = mod_pow(matrix[col][col], modulus - 2);
        for (std::size_t j = col; j <= q; ++j)
            matrix[col][j] = static_cast<std::uint32_t>(static_cast<std::int64_t>(matrix[col][j]) * inverse % modulus);
        for (std::size_t row = 0; row < q; ++row) {
            if (row == col) continue;
            const auto factor = matrix[row][col];
            for (std::size_t j = col; j <= q; ++j) {
                const auto product = static_cast<std::int64_t>(factor) * matrix[col][j] % modulus;
                auto value = static_cast<std::int64_t>(matrix[row][j]) - product;
                if (value < 0) value += modulus;
                matrix[row][j] = static_cast<std::uint32_t>(value);
            }
        }
    }
    store_i64_le(output, 0, p_value);
    store_i64_le(output, 8, q_value);
    std::size_t offset = 16;
    for (std::size_t m = 0; m <= p; ++m) {
        std::uint64_t value = coefficients[m];
        for (std::size_t j = 1; j <= (m < q ? m : q); ++j)
            value = (value + static_cast<std::uint64_t>(coefficients[m - j]) * matrix[j - 1][q]) % modulus;
        store_i64_le(output, offset, static_cast<std::int64_t>(value));
        offset += 8;
    }
    store_i64_le(output, offset, 1);
    offset += 8;
    for (std::size_t j = 0; j < q; ++j) {
        store_i64_le(output, offset, matrix[j][q]);
        offset += 8;
    }
    return static_cast<std::int64_t>(required);
}
