#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_order = 8;
constexpr std::int64_t mod = 1000000007;
constexpr std::int64_t max_n = 1000000000000LL;
constexpr std::size_t max_input_words = 18;
struct Matrix { std::int64_t cell[8][8]{}; };

Matrix multiply(const Matrix& left, const Matrix& right, std::int64_t order) {
    Matrix result{};
    for (std::int64_t row = 0; row < order; ++row)
        for (std::int64_t col = 0; col < order; ++col)
            for (std::int64_t inner = 0; inner < order; ++inner)
                result.cell[row][col] = (result.cell[row][col] +
                    (left.cell[row][inner] * right.cell[inner][col]) % mod) % mod;
    return result;
}
Matrix power(const Matrix& matrix, std::int64_t exponent, std::int64_t order) {
    if (exponent == 1) return matrix;
    if (exponent % 2 == 1) return multiply(matrix, power(matrix, exponent - 1, order), order);
    const Matrix half = power(matrix, exponent / 2, order);
    return multiply(half, half, order);
}
}

extern "C" std::int64_t matrix_exponentiation(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_words) return -1;
    const auto order = input[0];
    if (order < 1 || order > max_order || length != static_cast<std::size_t>(2 * order + 2)) return -1;
    for (std::int64_t i = 0; i < 2 * order; ++i) if (input[1 + i] < 0 || input[1 + i] >= mod) return -1;
    const auto n = input[2 * order + 1];
    if (n < 0 || n > max_n) return -1;
    if (n == 0) return 0;
    if (n <= order) return input[n];
    Matrix transition{};
    for (std::int64_t i = 0; i + 1 < order; ++i) transition.cell[i][i + 1] = 1;
    for (std::int64_t col = 0; col < order; ++col) transition.cell[order - 1][col] = input[order + 1 + order - 1 - col];
    transition = power(transition, n - 1, order);
    std::int64_t result = 0;
    for (std::int64_t i = 0; i < order; ++i) result = (result + (transition.cell[0][i] * input[1 + i]) % mod) % mod;
    return result;
}
