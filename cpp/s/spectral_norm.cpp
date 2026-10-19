#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 64;
constexpr double invalid_result = -1e300;

double matrix_entry(std::size_t i, std::size_t j) {
    const std::size_t triangular = (i + j) * (i + j + 1) / 2;
    return 1.0 / static_cast<double>(triangular + i + 1);
}

void multiply_a(std::size_t n, const double *input, double *output) {
    for (std::size_t i = 0; i < n; ++i) {
        double total = 0.0;
        for (std::size_t j = 0; j < n; ++j) total += matrix_entry(i, j) * input[j];
        output[i] = total;
    }
}

void multiply_at(std::size_t n, const double *input, double *output) {
    for (std::size_t i = 0; i < n; ++i) {
        double total = 0.0;
        for (std::size_t j = 0; j < n; ++j) total += matrix_entry(j, i) * input[j];
        output[i] = total;
    }
}

void multiply_ata(std::size_t n, const double *input, double *output,
                  double *temporary) {
    multiply_a(n, input, temporary);
    multiply_at(n, temporary, output);
}
}  // namespace

extern "C" double spectral_norm(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 1 || values[0] < 1 || values[0] > max_dimension)
        return invalid_result;
    const auto n = static_cast<std::size_t>(values[0]);
    double u[max_dimension], v[max_dimension], temporary[max_dimension];
    for (std::size_t i = 0; i < n; ++i) u[i] = 1.0;
    for (int iteration = 0; iteration < 10; ++iteration) {
        multiply_ata(n, u, v, temporary);
        multiply_ata(n, v, u, temporary);
    }
    double v_b_v = 0.0, v_v = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        v_b_v += u[i] * v[i];
        v_v += v[i] * v[i];
    }
    return std::sqrt(v_b_v / v_v);
}
