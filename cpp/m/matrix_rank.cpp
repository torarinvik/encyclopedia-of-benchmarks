#include <cstddef>
#include <cstdint>

namespace {
constexpr double matrix_rank_epsilon = 1e-10;

bool matrix_rank_is_zero(double value) noexcept {
    const double magnitude = value < 0.0 ? -value : value;
    return magnitude < matrix_rank_epsilon;
}
}  // namespace

extern "C" std::int64_t matrix_rank(const std::int64_t *values,
                                    std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 66) return -1;
    const std::int64_t rows_value = values[0];
    const std::int64_t cols_value = values[1];
    if (rows_value < 1 || rows_value > 8 || cols_value < 1 || cols_value > 8) return -1;

    const auto rows = static_cast<std::size_t>(rows_value);
    const auto cols = static_cast<std::size_t>(cols_value);
    const std::size_t cells = rows * cols;
    if (length != 2 + cells) return -1;

    double matrix[64]{};
    bool row_marked[8]{};
    for (std::size_t index = 0; index < cells; ++index) {
        if (values[2 + index] != 0 && values[2 + index] != 1) return -1;
        matrix[index] = static_cast<double>(values[2 + index]);
    }

    std::int64_t rank = 0;
    for (std::size_t col = 0; col < cols; ++col) {
        std::size_t pivot_row = rows;
        for (std::size_t row = 0; row < rows; ++row) {
            if (!row_marked[row] && !matrix_rank_is_zero(matrix[row * cols + col])) {
                pivot_row = row;
                break;
            }
        }
        if (pivot_row == rows) continue;

        ++rank;
        row_marked[pivot_row] = true;
        const double pivot_value = matrix[pivot_row * cols + col];
        for (std::size_t next_col = col + 1; next_col < cols; ++next_col) {
            matrix[pivot_row * cols + next_col] /= pivot_value;
        }
        for (std::size_t other_row = 0; other_row < rows; ++other_row) {
            if (other_row == pivot_row) continue;
            const double factor = matrix[other_row * cols + col];
            if (!matrix_rank_is_zero(factor)) {
                for (std::size_t next_col = col + 1; next_col < cols; ++next_col) {
                    matrix[other_row * cols + next_col] -=
                        matrix[pivot_row * cols + next_col] * factor;
                }
            }
        }
    }
    return rank;
}
