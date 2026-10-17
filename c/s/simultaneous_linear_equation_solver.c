#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define CAPACITY_ERROR INT64_C(-2)
#define MAX_EQUATIONS 5
#define MAX_INPUT_LENGTH 31
#define MAX_OUTPUT_BYTES 48

static int finite_rows(double matrix[MAX_EQUATIONS][MAX_EQUATIONS + 1], size_t n) {
    for (size_t row = 0; row < n; ++row)
        for (size_t col = 0; col <= n; ++col)
            if (!isfinite(matrix[row][col])) return 0;
    return 1;
}

static int simplify(double matrix[MAX_EQUATIONS][MAX_EQUATIONS + 1], size_t n) {
    if (n < 2 || matrix[0][0] == 0.0) return 0;
    const size_t cols = n + 1;
    for (size_t row = 0; row < n; ++row) {
        const double magnitude = matrix[row][0];
        if (magnitude != 0.0) {
            for (size_t col = 0; col < cols; ++col) matrix[row][col] /= magnitude;
        }
    }
    if (!finite_rows(matrix, n)) return 0;

    double first_row[MAX_EQUATIONS + 1];
    double first_column[MAX_EQUATIONS] = {0.0};
    for (size_t col = 0; col < cols; ++col) first_row[col] = matrix[0][col];
    for (size_t row = 1; row < n; ++row) {
        if (matrix[row][0] != 0.0) {
            for (size_t col = 0; col < cols; ++col)
                matrix[row][col] = first_row[col] - matrix[row][col];
        }
    }
    if (!finite_rows(matrix, n)) return 0;
    if (cols != 3) {
        double next[MAX_EQUATIONS][MAX_EQUATIONS + 1] = {{0.0}};
        for (size_t row = 1; row < n; ++row) {
            first_column[row - 1] = matrix[row][0];
            for (size_t col = 1; col < cols; ++col)
                next[row - 1][col - 1] = matrix[row][col];
        }
        if (!simplify(next, n - 1)) return 0;
        for (size_t col = 0; col < cols; ++col) matrix[0][col] = first_row[col];
        for (size_t row = 1; row < n; ++row) {
            matrix[row][0] = first_column[row - 1];
            for (size_t col = 1; col < cols; ++col)
                matrix[row][col] = next[row - 1][col - 1];
        }
    }
    return finite_rows(matrix, n);
}

static int64_t round_ticks(double value, int *valid) {
    const double halfway_limit = 4503599627370496.0;
    const int64_t tick_limit = INT64_C(2251799813685248);
    const double scaled = value * 100000.0;
    if (!isfinite(scaled) || scaled <= -halfway_limit || scaled >= halfway_limit) {
        *valid = 0;
        return 0;
    }
    const double lower = floor(scaled);
    const double midpoint = lower + 0.5;
    const double exact_side = fma(value, 100000.0, -midpoint);
    if (!isfinite(exact_side)) {
        *valid = 0;
        return 0;
    }
    int64_t rounded = (int64_t)lower;
    if (exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0)) ++rounded;
    if (rounded < -tick_limit || rounded > tick_limit) {
        *valid = 0;
        return 0;
    }
    const double rounded_value = (double)rounded / 100000.0;
    const double projected = rounded_value * 100000.0;
    if (!isfinite(projected)) {
        *valid = 0;
        return 0;
    }
    const double projected_lower = floor(projected);
    const double projected_midpoint = projected_lower + 0.5;
    int64_t ticks = (int64_t)projected_lower;
    if (projected > projected_midpoint ||
        (projected == projected_midpoint && ticks % 2 != 0)) ++ticks;
    if (ticks < -tick_limit || ticks > tick_limit) {
        *valid = 0;
        return 0;
    }
    *valid = 1;
    return ticks;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t simultaneous_linear_equation_solver(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_EQUATIONS) return INVALID_RESULT;
    const size_t n = (size_t)n_value;
    if (length != 1 + n * (n + 1)) return INVALID_RESULT;
    double matrix[MAX_EQUATIONS][MAX_EQUATIONS + 1] = {{0.0}};
    int has_zero = 0;
    for (size_t row = 0; row < n; ++row) {
        for (size_t col = 0; col <= n; ++col) {
            const int64_t raw = input[1 + row * (n + 1) + col];
            if (raw < -100000 || raw > 100000) return INVALID_RESULT;
            matrix[row][col] = (double)raw / 1000.0;
            if (raw == 0) has_zero = 1;
        }
    }
    if (n == 1) {
        if (matrix[0][0] == 0.0) return INVALID_RESULT;
    } else {
        if (has_zero) {
            size_t full_row = n;
            for (size_t row = 0; row < n; ++row) {
                int all_nonzero = 1;
                for (size_t col = 0; col <= n; ++col)
                    if (matrix[row][col] == 0.0) all_nonzero = 0;
                if (all_nonzero) { full_row = row; break; }
            }
            if (full_row == n) return INVALID_RESULT;
            if (full_row != 0) {
                double saved[MAX_EQUATIONS + 1];
                for (size_t col = 0; col <= n; ++col) saved[col] = matrix[full_row][col];
                for (size_t row = full_row; row > 0; --row)
                    for (size_t col = 0; col <= n; ++col) matrix[row][col] = matrix[row - 1][col];
                for (size_t col = 0; col <= n; ++col) matrix[0][col] = saved[col];
            }
        }
        if (!simplify(matrix, n)) return INVALID_RESULT;
    }

    double solutions[MAX_EQUATIONS] = {0.0};
    for (size_t row = n; row-- > 0;) {
        if (matrix[row][row] == 0.0) return INVALID_RESULT;
        double value = matrix[row][n];
        for (size_t col = row + 1; col < n; ++col)
            value -= matrix[row][col] * solutions[col];
        value /= matrix[row][row];
        if (!isfinite(value)) return INVALID_RESULT;
        solutions[row] = value;
    }
    uint8_t buffer[MAX_OUTPUT_BYTES] = {0};
    write_i64_le(buffer, 0, n_value);
    for (size_t i = 0; i < n; ++i) {
        int valid = 0;
        const int64_t ticks = round_ticks(solutions[i], &valid);
        if (!valid) return INVALID_RESULT;
        write_i64_le(buffer, 8 + 8 * i, ticks);
    }
    const size_t needed = 8 + 8 * n;
    if (output == NULL || capacity < needed) return CAPACITY_ERROR;
    for (size_t i = 0; i < needed; ++i) output[i] = buffer[i];
    return (int64_t)needed;
}
