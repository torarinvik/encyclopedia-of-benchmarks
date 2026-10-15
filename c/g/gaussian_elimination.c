#include <stddef.h>
#include <stdint.h>

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    union { double f; uint64_t u; } bits = { .f = value };
    for (size_t b = 0; b < 8; ++b) output[offset + b] = (uint8_t)(bits.u >> (8 * b));
}

int64_t gaussian_elimination(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1) return -1;
    const int64_t dimension = input[0];
    if (dimension < 2 || dimension > 8) return -1;
    const size_t n = (size_t)dimension;
    if (length != 1 + n * n + n) return -1;

    double matrix[8][9] = {{0.0}};
    for (size_t row = 0; row < n; ++row) {
        for (size_t col = 0; col < n; ++col) {
            const int64_t value = input[1 + row * n + col];
            if ((row == col && value != 32) ||
                (row != col && value != 0 && value != -1)) return -1;
            if ((row + 1 < col || col + 1 < row) && value != 0) return -1;
            if (row != col && value != input[1 + col * n + row]) return -1;
            matrix[row][col] = (double)value;
        }
        const int64_t rhs = input[1 + n * n + row];
        if (rhs < -100 || rhs > 100) return -1;
        matrix[row][n] = (double)rhs;
    }
    if (output == NULL || capacity < n * 8) return -2;

    // Forward elimination, matching the pinned no-pivot implementations.
    for (size_t step = 0; step + 1 < n; ++step) {
        for (size_t row = step + 1; row < n; ++row) {
            const double factor = matrix[row][step] / matrix[step][step];
            for (size_t col = step; col <= n; ++col)
                matrix[row][col] -= factor * matrix[step][col];
        }
    }
    double solution[8] = {0.0};
    for (size_t row = n; row-- > 0;) {
        double sum = 0.0;
        for (size_t col = row + 1; col < n; ++col)
            sum += matrix[row][col] * solution[col];
        solution[row] = (matrix[row][n] - sum) / matrix[row][row];
    }
    for (size_t i = 0; i < n; ++i) put_f64_le(output, i * 8, solution[i]);
    return (int64_t)(n * 8);
}
