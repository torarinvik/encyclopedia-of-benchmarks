#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr std::size_t MAX_INPUT_LENGTH = 132;
}

extern "C" double simplex(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const auto n_vars_value = input[0], n_artificial_value = input[1];
    const auto n_rows_value = input[2], n_cols_value = input[3];
    if (n_vars_value < 2 || n_vars_value > 4 || n_artificial_value < 0 || n_artificial_value > 2 ||
        n_rows_value < 3 || n_rows_value > 8 ||
        n_cols_value < n_vars_value + n_artificial_value + 1 || n_cols_value > 16 ||
        length != 4 + static_cast<std::size_t>(n_rows_value) * static_cast<std::size_t>(n_cols_value))
        return INVALID_RESULT;
    std::size_t rows = static_cast<std::size_t>(n_rows_value);
    std::size_t cols = static_cast<std::size_t>(n_cols_value);
    std::size_t artificial = static_cast<std::size_t>(n_artificial_value);
    double tableau[8][16]{};
    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t col = 0; col < cols; ++col)
            tableau[row][col] = static_cast<double>(input[4 + row * cols + col]) / 1000000.0;
        if (tableau[row][cols - 1] < 0.0) return INVALID_RESULT;
    }

    bool phase_one = artificial != 0;
    bool finished = false;
    for (std::size_t iteration = 0; iteration < 100; ++iteration) {
        if (finished) {
            const double result = std::fabs(tableau[0][cols - 1]);
            return std::isfinite(result) ? result : INVALID_RESULT;
        }
        const std::size_t stages = phase_one ? 2 : 1;
        const double sign = phase_one ? 1.0 : -1.0;
        std::size_t pivot_col = 0;
        double best = sign * tableau[0][0];
        for (std::size_t col = 1; col + 1 < cols; ++col) {
            const double score = sign * tableau[0][col];
            if (score > best) { best = score; pivot_col = col; }
        }
        if (best <= 0.0) {
            if (phase_one) {
                double compacted[8][16]{};
                const std::size_t first_artificial = cols - artificial - 1;
                for (std::size_t row = 1; row < rows; ++row) {
                    std::size_t new_col = 0;
                    for (std::size_t col = 0; col < cols; ++col) {
                        if (col >= first_artificial && col < cols - 1) continue;
                        compacted[row - 1][new_col++] = tableau[row][col];
                    }
                }
                --rows;
                cols -= artificial;
                artificial = 0;
                for (std::size_t row = 0; row < rows; ++row)
                    for (std::size_t col = 0; col < cols; ++col)
                        tableau[row][col] = compacted[row][col];
                phase_one = false;
            } else {
                finished = true;
            }
            continue;
        }
        std::size_t pivot_row = 0;
        double best_ratio = 0.0;
        bool found = false;
        for (std::size_t row = stages; row < rows; ++row) {
            const double divisor = tableau[row][pivot_col];
            if (divisor > 0.0) {
                const double ratio = tableau[row][cols - 1] / divisor;
                if (!std::isfinite(ratio)) return INVALID_RESULT;
                if (!found || ratio < best_ratio) {
                    found = true;
                    best_ratio = ratio;
                    pivot_row = row;
                }
            }
        }
        if (!found) return INVALID_RESULT;

        double normalized[16]{};
        const double pivot = tableau[pivot_row][pivot_col];
        for (std::size_t col = 0; col < cols; ++col) normalized[col] = tableau[pivot_row][col] / pivot;
        double column_values[8]{};
        for (std::size_t row = 0; row < rows; ++row) column_values[row] = tableau[row][pivot_col];
        for (std::size_t row = 0; row < rows; ++row) {
            const double coefficient = column_values[row];
            for (std::size_t col = 0; col < cols; ++col)
                tableau[row][col] += -coefficient * normalized[col];
        }
        for (std::size_t col = 0; col < cols; ++col) tableau[pivot_row][col] = normalized[col];
        for (std::size_t row = 0; row < rows; ++row)
            for (std::size_t col = 0; col < cols; ++col)
                if (!std::isfinite(tableau[row][col])) return INVALID_RESULT;
    }
    return INVALID_RESULT;
}
