#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t INVALID_RESULT = -1;
constexpr std::int64_t CAPACITY_ERROR = -2;
using Matrix = double[5][6];

bool finite_matrix(const Matrix &matrix, std::size_t n) {
    for (std::size_t row = 0; row < n; ++row)
        for (std::size_t col = 0; col <= n; ++col)
            if (!std::isfinite(matrix[row][col])) return false;
    return true;
}

bool simplify(Matrix &matrix, std::size_t n) {
    if (n < 2 || matrix[0][0] == 0.0) return false;
    const std::size_t cols = n + 1;
    for (std::size_t row = 0; row < n; ++row) {
        const double magnitude = matrix[row][0];
        if (magnitude != 0.0)
            for (std::size_t col = 0; col < cols; ++col) matrix[row][col] /= magnitude;
    }
    if (!finite_matrix(matrix, n)) return false;
    double first_row[6]{};
    double first_column[5]{};
    for (std::size_t col = 0; col < cols; ++col) first_row[col] = matrix[0][col];
    for (std::size_t row = 1; row < n; ++row) {
        if (matrix[row][0] != 0.0)
            for (std::size_t col = 0; col < cols; ++col)
                matrix[row][col] = first_row[col] - matrix[row][col];
    }
    if (!finite_matrix(matrix, n)) return false;
    if (cols != 3) {
        Matrix next{};
        for (std::size_t row = 1; row < n; ++row) {
            first_column[row - 1] = matrix[row][0];
            for (std::size_t col = 1; col < cols; ++col)
                next[row - 1][col - 1] = matrix[row][col];
        }
        if (!simplify(next, n - 1)) return false;
        for (std::size_t col = 0; col < cols; ++col) matrix[0][col] = first_row[col];
        for (std::size_t row = 1; row < n; ++row) {
            matrix[row][0] = first_column[row - 1];
            for (std::size_t col = 1; col < cols; ++col)
                matrix[row][col] = next[row - 1][col - 1];
        }
    }
    return finite_matrix(matrix, n);
}

bool round_ticks(double value, std::int64_t &ticks) {
    constexpr double halfway_limit = 4.503599627370496e15;
    constexpr std::int64_t tick_limit = 2251799813685248;
    const double scaled = value * 100000.0;
    if (!std::isfinite(scaled) || scaled <= -halfway_limit || scaled >= halfway_limit) return false;
    const double lower = std::floor(scaled);
    const double midpoint = lower + 0.5;
    const double exact_side = std::fma(value, 100000.0, -midpoint);
    if (!std::isfinite(exact_side)) return false;
    std::int64_t rounded = static_cast<std::int64_t>(lower);
    if (exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0)) ++rounded;
    if (rounded < -tick_limit || rounded > tick_limit) return false;
    const double rounded_value = static_cast<double>(rounded) / 100000.0;
    const double projected = rounded_value * 100000.0;
    if (!std::isfinite(projected)) return false;
    const double projected_lower = std::floor(projected);
    const double projected_midpoint = projected_lower + 0.5;
    ticks = static_cast<std::int64_t>(projected_lower);
    if (projected > projected_midpoint ||
        (projected == projected_midpoint && ticks % 2 != 0)) ++ticks;
    if (ticks < -tick_limit || ticks > tick_limit) return false;
    return true;
}

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t simultaneous_linear_equation_solver(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 31) return INVALID_RESULT;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > 5) return INVALID_RESULT;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + n * (n + 1)) return INVALID_RESULT;
    Matrix matrix{};
    bool has_zero = false;
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t col = 0; col <= n; ++col) {
            const auto raw = input[1 + row * (n + 1) + col];
            if (raw < -100000 || raw > 100000) return INVALID_RESULT;
            matrix[row][col] = static_cast<double>(raw) / 1000.0;
            has_zero = has_zero || raw == 0;
        }
    }
    if (n == 1) {
        if (matrix[0][0] == 0.0) return INVALID_RESULT;
    } else {
        if (has_zero) {
            std::size_t full_row = n;
            for (std::size_t row = 0; row < n; ++row) {
                bool all_nonzero = true;
                for (std::size_t col = 0; col <= n; ++col)
                    if (matrix[row][col] == 0.0) all_nonzero = false;
                if (all_nonzero) { full_row = row; break; }
            }
            if (full_row == n) return INVALID_RESULT;
            if (full_row != 0) {
                double saved[6]{};
                for (std::size_t col = 0; col <= n; ++col) saved[col] = matrix[full_row][col];
                for (std::size_t row = full_row; row > 0; --row)
                    for (std::size_t col = 0; col <= n; ++col) matrix[row][col] = matrix[row - 1][col];
                for (std::size_t col = 0; col <= n; ++col) matrix[0][col] = saved[col];
            }
        }
        if (!simplify(matrix, n)) return INVALID_RESULT;
    }

    double solutions[5]{};
    for (std::size_t row = n; row-- > 0;) {
        if (matrix[row][row] == 0.0) return INVALID_RESULT;
        double value = matrix[row][n];
        for (std::size_t col = row + 1; col < n; ++col) value -= matrix[row][col] * solutions[col];
        value /= matrix[row][row];
        if (!std::isfinite(value)) return INVALID_RESULT;
        solutions[row] = value;
    }
    const std::size_t needed = 8 + 8 * n;
    std::uint8_t buffer[48]{};
    write_i64_le(buffer, 0, n_value);
    for (std::size_t i = 0; i < n; ++i) {
        std::int64_t ticks = 0;
        if (!round_ticks(solutions[i], ticks)) return INVALID_RESULT;
        write_i64_le(buffer, 8 + 8 * i, ticks);
    }
    if (output == nullptr || capacity < needed) return CAPACITY_ERROR;
    for (std::size_t i = 0; i < needed; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(needed);
}
