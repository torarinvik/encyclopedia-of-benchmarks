#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::int64_t kModulus = 998244353;
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxInputValues = 1 + kMaxN * kMaxN + 1;

std::int64_t normalize(std::int64_t value) {
    value %= kModulus;
    return value < 0 ? value + kModulus : value;
}

std::int64_t multiply(std::int64_t left, std::int64_t right) {
    return (left * right) % kModulus;
}

std::int64_t power(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}

void store_i64_le(std::uint8_t *output, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t characteristic_polynomial(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInputValues) return -1;
    const auto n_value = input[0];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + n * n) return -1;

    std::array<std::array<std::int64_t, kMaxN>, kMaxN> matrix{};
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const auto value = input[1 + row * n + column];
            if (value < 0 || value >= kModulus) return -1;
            matrix[row][column] = value;
        }
    }

    for (std::size_t column = 0; column + 2 < n; ++column) {
        auto pivot = column + 1;
        while (pivot < n && matrix[pivot][column] == 0) ++pivot;
        if (pivot == n) continue;
        if (pivot != column + 1) {
            std::swap(matrix[column + 1], matrix[pivot]);
            for (std::size_t row = 0; row < n; ++row)
                std::swap(matrix[row][column + 1], matrix[row][pivot]);
        }
        const auto inverse = power(matrix[column + 1][column], kModulus - 2);
        for (std::size_t row = column + 2; row < n; ++row) {
            if (matrix[row][column] == 0) continue;
            const auto factor = multiply(matrix[row][column], inverse);
            for (std::size_t k = 0; k < n; ++k)
                matrix[row][k] = normalize(
                    matrix[row][k] - multiply(factor, matrix[column + 1][k]));
            for (std::size_t k = 0; k < n; ++k)
                matrix[k][column + 1] = normalize(
                    matrix[k][column + 1] + multiply(factor, matrix[k][row]));
        }
    }

    std::array<std::array<std::int64_t, kMaxN + 1>, kMaxN + 1> coefficients{};
    coefficients[0][0] = 1;
    for (std::size_t size = 1; size <= n; ++size) {
        for (std::size_t degree = 0; degree <= size; ++degree) {
            auto value = degree == 0 ? 0 : coefficients[size - 1][degree - 1];
            if (degree < size)
                value -= multiply(matrix[size - 1][size - 1],
                                  coefficients[size - 1][degree]);
            coefficients[size][degree] = normalize(value);
        }
        auto subdiagonal_product = std::int64_t{1};
        for (int start = static_cast<int>(size) - 2; start >= 0; --start) {
            subdiagonal_product = multiply(
                subdiagonal_product, matrix[start + 1][start]);
            const auto term = multiply(subdiagonal_product, matrix[start][size - 1]);
            for (int degree = 0; degree <= start; ++degree)
                coefficients[size][degree] = normalize(
                    coefficients[size][degree] -
                    multiply(term, coefficients[start][degree]));
        }
    }

    const auto output_bytes = 8 * (n + 1);
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t degree = 0; degree <= n; ++degree)
        store_i64_le(output + 8 * degree, coefficients[n][degree]);
    return static_cast<std::int64_t>(output_bytes);
}
