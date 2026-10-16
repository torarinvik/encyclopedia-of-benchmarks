#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t rayleigh_quotient(const double *values, size_t length,
                          double *output, size_t capacity) {
    if (values == NULL || length < 1 || length > 273) return -1;
    for (size_t i = 0; i < length; ++i)
        if (!isfinite(values[i])) return -1;

    const double n_value = values[0];
    if (n_value < 1.0 || n_value > 16.0 || floor(n_value) != n_value) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + n * n + n) return -1;
    const double *matrix = values + 1;
    const double *vector = matrix + n * n;

    for (size_t i = 0; i < n * n; ++i)
        if (matrix[i] < -1000.0 || matrix[i] > 1000.0) return -1;
    for (size_t row = 0; row < n; ++row)
        for (size_t col = row + 1; col < n; ++col)
            if (matrix[row * n + col] != matrix[col * n + row]) return -1;

    double denominator = 0.0;
    for (size_t i = 0; i < n; ++i) {
        if (vector[i] < -100.0 || vector[i] > 100.0) return -1;
        denominator += vector[i] * vector[i];
    }
    if (denominator <= 0.0 || !isfinite(denominator)) return -1;

    double numerator = 0.0;
    for (size_t col = 0; col < n; ++col) {
        double v_star_dot = 0.0;
        for (size_t row = 0; row < n; ++row)
            v_star_dot += vector[row] * matrix[row * n + col];
        numerator += v_star_dot * vector[col];
    }
    const double quotient = numerator / denominator;

    if (output == NULL || capacity < 1) return -2;
    output[0] = quotient;
    return 1;
}
