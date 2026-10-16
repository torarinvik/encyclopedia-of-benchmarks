#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr int MAX_DIMENSION = 8;
constexpr std::int64_t MAX_MATRIX_MICRO = 1000000000;
constexpr std::int64_t MAX_VECTOR_MICRO = 1000000000;
constexpr std::int64_t MAX_SPECTRAL_MICRO = 1000000000;
constexpr std::int64_t MAX_ITERATIONS = 1000;

void write_f64_le(std::uint8_t *output, std::size_t offset, double value)
{
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t chebyshev_iteration(const std::int64_t *values, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length < 1 || values[0] < 1 || values[0] > MAX_DIMENSION) return -1;
    const std::size_t n = static_cast<std::size_t>(values[0]);
    if (length != 1 + n * n + 2 * n + 4) return -1;
    const std::size_t matrix_end = 1 + n * n, vector_end = matrix_end + 2 * n;
    double matrix[MAX_DIMENSION * MAX_DIMENSION] = {}, b[MAX_DIMENSION] = {}, x[MAX_DIMENSION] = {};
    double residual[MAX_DIMENSION] = {}, direction[MAX_DIMENSION] = {};
    for (std::size_t i = 0; i < n * n; ++i) {
        const auto value = values[1 + i];
        if (value < -MAX_MATRIX_MICRO || value > MAX_MATRIX_MICRO) return -1;
        matrix[i] = static_cast<double>(value) / 1000000.0;
    }
    for (std::size_t i = 0; i < n; ++i) {
        const auto rhs = values[matrix_end + i], guess = values[matrix_end + n + i];
        if (rhs < -MAX_VECTOR_MICRO || rhs > MAX_VECTOR_MICRO ||
            guess < -MAX_VECTOR_MICRO || guess > MAX_VECTOR_MICRO) return -1;
        b[i] = static_cast<double>(rhs) / 1000000.0;
        x[i] = static_cast<double>(guess) / 1000000.0;
    }
    const auto min_micro = values[vector_end], max_micro = values[vector_end + 1];
    const auto iteration_count = values[vector_end + 2], tolerance_micro = values[vector_end + 3];
    if (min_micro < 1 || max_micro <= min_micro || max_micro > MAX_SPECTRAL_MICRO ||
        iteration_count < 1 || iteration_count > MAX_ITERATIONS ||
        tolerance_micro < 1 || tolerance_micro > MAX_VECTOR_MICRO) return -1;
    const double min_eigenvalue = static_cast<double>(min_micro) / 1000000.0;
    const double max_eigenvalue = static_cast<double>(max_micro) / 1000000.0;
    const double tolerance = static_cast<double>(tolerance_micro) / 1000000.0;
    const std::size_t output_bytes = n * sizeof(double);
    if (output == nullptr || output_capacity < output_bytes) return -2;

    for (std::size_t row = 0; row < n; ++row) {
        double product = 0.0;
        for (std::size_t column = 0; column < n; ++column) product += matrix[row * n + column] * x[column];
        residual[row] = b[row] - product;
    }
    const double d = (max_eigenvalue + min_eigenvalue) / 2.0;
    const double c = (max_eigenvalue - min_eigenvalue) / 2.0;
    double alpha = 0.0, alpha_previous = 0.0;
    for (std::int64_t iteration = 0; iteration < iteration_count; ++iteration) {
        double squares = 0.0;
        for (std::size_t i = 0; i < n; ++i) squares += residual[i] * residual[i];
        if (std::sqrt(squares) < tolerance) break;
        if (iteration == 0) {
            alpha = 1.0 / d;
            for (std::size_t i = 0; i < n; ++i) direction[i] = residual[i];
        } else {
            const double half_step = c * alpha_previous / 2.0;
            const double beta = half_step * half_step;
            alpha = 1.0 / (d - beta / alpha_previous);
            const double scale = beta / alpha_previous;
            for (std::size_t i = 0; i < n; ++i) direction[i] = residual[i] + scale * direction[i];
        }
        for (std::size_t i = 0; i < n; ++i) x[i] += alpha * direction[i];
        for (std::size_t row = 0; row < n; ++row) {
            double product = 0.0;
            for (std::size_t column = 0; column < n; ++column) product += matrix[row * n + column] * x[column];
            residual[row] = b[row] - product;
        }
        alpha_previous = alpha;
    }
    for (std::size_t i = 0; i < n; ++i) write_f64_le(output, i * 8, x[i]);
    return static_cast<std::int64_t>(output_bytes);
}
