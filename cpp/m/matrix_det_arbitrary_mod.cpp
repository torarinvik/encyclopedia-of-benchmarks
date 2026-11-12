#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxInputValues = 2 + kMaxN * kMaxN + 1;
constexpr std::int64_t kMaxModulus = 1'000'000'000;

std::int64_t normalize(std::int64_t value, std::int64_t modulus) {
    value %= modulus;
    return value < 0 ? value + modulus : value;
}

void store_i64_le(std::uint8_t *output, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t matrix_det_arbitrary_mod(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputValues) return -1;
    const auto n_value = input[0], modulus = input[1];
    if (n_value < 0 || n_value > 8 || modulus < 2 || modulus > kMaxModulus) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 2 + n * n) return -1;

    std::array<std::array<std::int64_t, kMaxN>, kMaxN> matrix{};
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const auto value = input[2 + row * n + column];
            if (value < 0 || value >= modulus) return -1;
            matrix[row][column] = value;
        }
    }

    std::int64_t determinant = 1;
    bool sign = false;
    for (std::size_t column = 0; column < n; ++column) {
        auto pivot = column;
        while (pivot < n && matrix[pivot][column] == 0) ++pivot;
        if (pivot == n) {
            determinant = 0;
            break;
        }
        if (pivot != column) {
            matrix[pivot].swap(matrix[column]);
            sign = !sign;
        }
        for (std::size_t row = column + 1; row < n; ++row) {
            auto left = matrix[column][column];
            auto right = matrix[row][column];
            if (right == 0) continue;
            std::int64_t a0 = 1, a1 = 0, b0 = 0, b1 = 1;
            while (left != 0 && right != 0) {
                if (left < right) {
                    const auto quotient = right / left;
                    right -= quotient * left;
                    b0 = normalize(b0 - a0 * quotient, modulus);
                    b1 = normalize(b1 - a1 * quotient, modulus);
                } else {
                    const auto quotient = left / right;
                    left -= quotient * right;
                    a0 = normalize(a0 - b0 * quotient, modulus);
                    a1 = normalize(a1 - b1 * quotient, modulus);
                }
            }
            for (std::size_t k = column; k < n; ++k) {
                const auto old_top = matrix[column][k];
                const auto old_bottom = matrix[row][k];
                matrix[column][k] = normalize(old_top * a0 + old_bottom * a1, modulus);
                matrix[row][k] = normalize(old_top * b0 + old_bottom * b1, modulus);
            }
            if (left == 0) {
                matrix[column].swap(matrix[row]);
                sign = !sign;
            }
        }
        determinant = determinant * matrix[column][column] % modulus;
        if (determinant == 0) break;
    }
    if (sign && determinant != 0) determinant = modulus - determinant;
    if (output == nullptr || capacity < 8) return -2;
    store_i64_le(output, determinant);
    return 8;
}
