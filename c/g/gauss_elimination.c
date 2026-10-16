#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    union { double f; uint64_t u; } bits = { .f = value };
    for (size_t b = 0; b < 8; ++b) output[offset + b] = (uint8_t)(bits.u >> (8 * b));
}

int64_t gauss_elimination(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 2 || input[0] > 8) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + n * n + n) return -1;
    float matrix[8][9] = {{0.0f}};
    for (size_t row = 0; row < n; ++row) {
        for (size_t col = 0; col < n; ++col) {
            int64_t value = input[1 + row * n + col];
            if (value < -100 || value > 100) return -1;
            matrix[row][col] = (float)value;
        }
        int64_t rhs = input[1 + n * n + row];
        if (rhs < -100 || rhs > 100) return -1;
        matrix[row][n] = (float)rhs;
    }

    for (size_t step = 0; step + 1 < n; ++step) {
        size_t pivot = step;
        float maximum = matrix[step][step] < 0.0f ? -matrix[step][step] : matrix[step][step];
        for (size_t row = step; row < n; ++row) {
            float magnitude = matrix[row][step] < 0.0f ? -matrix[row][step] : matrix[row][step];
            if (maximum < magnitude) { maximum = magnitude; pivot = row; }
        }
        if (maximum == 0.0f) return -1;
        if (pivot != step) for (size_t col = 0; col <= n; ++col) {
            float temporary = matrix[step][col];
            matrix[step][col] = matrix[pivot][col];
            matrix[pivot][col] = temporary;
        }
        for (size_t row = step + 1; row < n; ++row) {
            float factor = -(matrix[row][step] / matrix[step][step]);
            for (size_t col = 0; col <= n; ++col)
                matrix[row][col] = matrix[row][col] + matrix[step][col] * factor;
        }
    }
    if (matrix[n - 1][n - 1] == 0.0f) return -1;
    float solution[8] = {0.0f};
    size_t count = 1;
    for (size_t row = n; row-- > 0;) {
        float sum = 0.0f;
        size_t col = n - 1;
        for (size_t j = 0; j < count - 1; ++j) {
            sum = sum + matrix[row][col] * solution[col];
            --col;
        }
        solution[row] = (matrix[row][n] - sum) / matrix[row][row];
        ++count;
    }
    if (output == NULL || capacity < n * 8) return -2;
    for (size_t i = 0; i < n; ++i) {
        char formatted[48];
        if (snprintf(formatted, sizeof formatted, "%.2f", (double)solution[i]) < 0) return -1;
        put_f64_le(output, i * 8, strtod(formatted, NULL));
    }
    return (int64_t)(n * 8);
}
