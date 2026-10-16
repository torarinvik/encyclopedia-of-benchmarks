#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_DIMENSION 8
#define MAX_MATRIX_MICRO INT64_C(1000000000)
#define MAX_VECTOR_MICRO INT64_C(1000000000)
#define MAX_SPECTRAL_MICRO INT64_C(1000000000)
#define MAX_ITERATIONS 1000

static void write_f64_le(uint8_t *output, size_t offset, double value)
{
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t chebyshev_iteration(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || values[0] < 1 || values[0] > MAX_DIMENSION) return -1;
    const size_t n = (size_t)values[0];
    if (length != 1 + n * n + 2 * n + 4) return -1;
    const size_t matrix_end = 1 + n * n;
    const size_t vector_end = matrix_end + 2 * n;
    double matrix[MAX_DIMENSION * MAX_DIMENSION] = {0};
    double b[MAX_DIMENSION] = {0}, x[MAX_DIMENSION] = {0};
    double residual[MAX_DIMENSION] = {0}, direction[MAX_DIMENSION] = {0};
    for (size_t i = 0; i < n * n; ++i) {
        const int64_t value = values[1 + i];
        if (value < -MAX_MATRIX_MICRO || value > MAX_MATRIX_MICRO) return -1;
        matrix[i] = (double)value / 1000000.0;
    }
    for (size_t i = 0; i < n; ++i) {
        const int64_t rhs = values[matrix_end + i];
        const int64_t guess = values[matrix_end + n + i];
        if (rhs < -MAX_VECTOR_MICRO || rhs > MAX_VECTOR_MICRO ||
            guess < -MAX_VECTOR_MICRO || guess > MAX_VECTOR_MICRO) return -1;
        b[i] = (double)rhs / 1000000.0;
        x[i] = (double)guess / 1000000.0;
    }
    const int64_t min_micro = values[vector_end];
    const int64_t max_micro = values[vector_end + 1];
    const int64_t iteration_count = values[vector_end + 2];
    const int64_t tolerance_micro = values[vector_end + 3];
    if (min_micro < 1 || max_micro <= min_micro || max_micro > MAX_SPECTRAL_MICRO ||
        iteration_count < 1 || iteration_count > MAX_ITERATIONS ||
        tolerance_micro < 1 || tolerance_micro > MAX_VECTOR_MICRO) return -1;
    const double min_eigenvalue = (double)min_micro / 1000000.0;
    const double max_eigenvalue = (double)max_micro / 1000000.0;
    const double tolerance = (double)tolerance_micro / 1000000.0;
    const size_t output_bytes = n * sizeof(double);
    if (output == NULL || output_capacity < output_bytes) return -2;

    for (size_t row = 0; row < n; ++row) {
        double product = 0.0;
        for (size_t column = 0; column < n; ++column)
            product += matrix[row * n + column] * x[column];
        residual[row] = b[row] - product;
    }
    const double d = (max_eigenvalue + min_eigenvalue) / 2.0;
    const double c = (max_eigenvalue - min_eigenvalue) / 2.0;
    double alpha = 0.0, alpha_previous = 0.0;
    for (int64_t iteration = 0; iteration < iteration_count; ++iteration) {
        double squares = 0.0;
        for (size_t i = 0; i < n; ++i) squares += residual[i] * residual[i];
        if (sqrt(squares) < tolerance) break;
        if (iteration == 0) {
            alpha = 1.0 / d;
            for (size_t i = 0; i < n; ++i) direction[i] = residual[i];
        } else {
            const double half_step = c * alpha_previous / 2.0;
            const double beta = half_step * half_step;
            alpha = 1.0 / (d - beta / alpha_previous);
            const double direction_scale = beta / alpha_previous;
            for (size_t i = 0; i < n; ++i) direction[i] = residual[i] + direction_scale * direction[i];
        }
        for (size_t i = 0; i < n; ++i) x[i] += alpha * direction[i];
        for (size_t row = 0; row < n; ++row) {
            double product = 0.0;
            for (size_t column = 0; column < n; ++column)
                product += matrix[row * n + column] * x[column];
            residual[row] = b[row] - product;
        }
        alpha_previous = alpha;
    }
    for (size_t i = 0; i < n; ++i) write_f64_le(output, i * 8, x[i]);
    return (int64_t)output_bytes;
}
