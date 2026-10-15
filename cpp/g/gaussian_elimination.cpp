#include <cstddef>
#include <cstdint>

static void put_f64_le(std::uint8_t *output, std::size_t offset, double value) {
    union Bits { double f; std::uint64_t u; } bits{value};
    for (std::size_t b = 0; b < 8; ++b) output[offset + b] = static_cast<std::uint8_t>(bits.u >> (8 * b));
}

// The pinned C++ source is a console program; this adapter keeps its
// elimination/back-substitution arithmetic and returns the solution vector.
extern "C" std::int64_t gaussian_elimination(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || input[0] < 2 || input[0] > 8) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + n * n + n) return -1;
    double matrix[8][9]{};
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t col = 0; col < n; ++col) {
            const auto value = input[1 + row * n + col];
            if ((row == col && value != 32) || (row != col && value != 0 && value != -1)) return -1;
            if ((row + 1 < col || col + 1 < row) && value != 0) return -1;
            if (row != col && value != input[1 + col * n + row]) return -1;
            matrix[row][col] = static_cast<double>(value);
        }
        const auto rhs = input[1 + n * n + row];
        if (rhs < -100 || rhs > 100) return -1;
        matrix[row][n] = static_cast<double>(rhs);
    }
    if (output == nullptr || capacity < n * 8) return -2;
    for (std::size_t step = 0; step + 1 < n; ++step) {
        for (std::size_t row = step; row < n - 1; ++row) {
            const double factor = matrix[row + 1][step] / matrix[step][step];
            for (std::size_t col = step; col <= n; ++col)
                matrix[row + 1][col] = matrix[row + 1][col] - factor * matrix[step][col];
        }
    }
    double solution[8]{};
    for (std::size_t row = n; row-- > 0;) {
        double sum = 0.0;
        for (std::size_t col = n; col-- > row + 1;)
            sum += solution[col] * matrix[row][col];
        solution[row] = (matrix[row][n] - sum) / matrix[row][row];
    }
    for (std::size_t i = 0; i < n; ++i) put_f64_le(output, i * 8, solution[i]);
    return static_cast<std::int64_t>(n * 8);
}
