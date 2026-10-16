#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" int64_t rayleigh_quotient(const double *values, std::size_t length,
                                      double *output, std::size_t capacity) {
    if (values == nullptr || length < 1 || length > 273) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (!std::isfinite(values[i])) return -1;

    const double n_value = values[0];
    if (n_value < 1.0 || n_value > 16.0 || std::floor(n_value) != n_value) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    if (length != 1 + n * n + n) return -1;
    const double *matrix = values + 1;
    const double *vector = matrix + n * n;
    for (std::size_t i = 0; i < n * n; ++i)
        if (matrix[i] < -1000.0 || matrix[i] > 1000.0) return -1;
    for (std::size_t row = 0; row < n; ++row)
        for (std::size_t col = row + 1; col < n; ++col)
            if (matrix[row * n + col] != matrix[col * n + row]) return -1;

    double denominator = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        if (vector[i] < -100.0 || vector[i] > 100.0) return -1;
        denominator += vector[i] * vector[i];
    }
    if (denominator <= 0.0 || !std::isfinite(denominator)) return -1;

    double numerator = 0.0;
    for (std::size_t col = 0; col < n; ++col) {
        double v_star_dot = 0.0;
        for (std::size_t row = 0; row < n; ++row)
            v_star_dot += vector[row] * matrix[row * n + col];
        numerator += v_star_dot * vector[col];
    }
    const double quotient = numerator / denominator;
    if (output == nullptr || capacity < 1) return -2;
    output[0] = quotient;
    return 1;
}
