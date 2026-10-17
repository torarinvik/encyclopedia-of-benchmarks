/* Seven-product Strassen multiplication for bounded square matrices. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_INPUT_LENGTH 129

static void strassen_multiply(const int64_t *a, const int64_t *b,
                              int64_t *c, size_t n)
{
    if (n == 1) {
        c[0] = a[0] * b[0];
        return;
    }

    const size_t half = n / 2;
    int64_t x[16], y[16];
    int64_t m1[16], m2[16], m3[16], m4[16], m5[16], m6[16], m7[16];
    for (size_t row = 0; row < half; ++row) {
        for (size_t column = 0; column < half; ++column) {
            const size_t i = row * half + column;
            const size_t a11 = row * n + column;
            const size_t a12 = row * n + column + half;
            const size_t a21 = (row + half) * n + column;
            const size_t a22 = (row + half) * n + column + half;
            const size_t b11 = a11, b12 = a12, b21 = a21, b22 = a22;

            x[i] = a[a11] + a[a22]; y[i] = b[b11] + b[b22];
        }
    }
    strassen_multiply(x, y, m1, half);
    for (size_t row = 0; row < half; ++row) {
        for (size_t column = 0; column < half; ++column) {
            const size_t i = row * half + column;
            const size_t a21 = (row + half) * n + column;
            const size_t a22 = (row + half) * n + column + half;
            x[i] = a[a21] + a[a22]; y[i] = b[row * n + column];
        }
    }
    strassen_multiply(x, y, m2, half);
    for (size_t row = 0; row < half; ++row) {
        for (size_t column = 0; column < half; ++column) {
            const size_t i = row * half + column;
            const size_t b12 = row * n + column + half;
            const size_t b22 = (row + half) * n + column + half;
            x[i] = a[row * n + column]; y[i] = b[b12] - b[b22];
        }
    }
    strassen_multiply(x, y, m3, half);
    for (size_t row = 0; row < half; ++row) {
        for (size_t column = 0; column < half; ++column) {
            const size_t i = row * half + column;
            const size_t a22 = (row + half) * n + column + half;
            const size_t b21 = (row + half) * n + column;
            const size_t b11 = row * n + column;
            x[i] = a[a22]; y[i] = b[b21] - b[b11];
        }
    }
    strassen_multiply(x, y, m4, half);
    for (size_t row = 0; row < half; ++row) {
        for (size_t column = 0; column < half; ++column) {
            const size_t i = row * half + column;
            const size_t a11 = row * n + column;
            const size_t a12 = row * n + column + half;
            const size_t b22 = (row + half) * n + column + half;
            x[i] = a[a11] + a[a12]; y[i] = b[b22];
        }
    }
    strassen_multiply(x, y, m5, half);
    for (size_t row = 0; row < half; ++row) {
        for (size_t column = 0; column < half; ++column) {
            const size_t i = row * half + column;
            const size_t a21 = (row + half) * n + column;
            const size_t a11 = row * n + column;
            const size_t b11 = row * n + column;
            const size_t b12 = row * n + column + half;
            x[i] = a[a21] - a[a11]; y[i] = b[b11] + b[b12];
        }
    }
    strassen_multiply(x, y, m6, half);
    for (size_t row = 0; row < half; ++row) {
        for (size_t column = 0; column < half; ++column) {
            const size_t i = row * half + column;
            const size_t a12 = row * n + column + half;
            const size_t a22 = (row + half) * n + column + half;
            const size_t b21 = (row + half) * n + column;
            const size_t b22 = (row + half) * n + column + half;
            x[i] = a[a12] - a[a22]; y[i] = b[b21] + b[b22];
        }
    }
    strassen_multiply(x, y, m7, half);

    for (size_t row = 0; row < half; ++row) {
        for (size_t column = 0; column < half; ++column) {
            const size_t i = row * half + column;
            const size_t c11 = row * n + column;
            const size_t c12 = row * n + column + half;
            const size_t c21 = (row + half) * n + column;
            const size_t c22 = (row + half) * n + column + half;
            c[c11] = m1[i] + m4[i] - m5[i] + m7[i];
            c[c12] = m3[i] + m5[i];
            c[c21] = m2[i] + m4[i];
            c[c22] = m1[i] - m2[i] + m3[i] + m6[i];
        }
    }
}

int64_t strassen_matrix_multiplication(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value != 1 && n_value != 2 && n_value != 4 && n_value != 8) return -1;
    const size_t n = (size_t)n_value;
    const size_t matrix_cells = n * n;
    if (length != 1 + 2 * matrix_cells) return -1;
    for (size_t i = 0; i < 2 * matrix_cells; ++i) {
        if (input[1 + i] < -2 || input[1 + i] > 2) return -1;
    }

    const size_t output_bytes = 8 * matrix_cells;
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t result[MAX_N * MAX_N];
    strassen_multiply(input + 1, input + 1 + matrix_cells, result, n);
    for (size_t i = 0; i < matrix_cells; ++i) {
        uint64_t bits = (uint64_t)result[i];
        for (size_t byte = 0; byte < 8; ++byte) {
            output[i * 8 + byte] = (uint8_t)(bits & 255);
            bits >>= 8;
        }
    }
    return (int64_t)output_bytes;
}
