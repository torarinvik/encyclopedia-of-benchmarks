/* Bounded Takahasi-Mori tanh-sinh quadrature on [-1,1]. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_input_length = 3;
constexpr double pi = 3.14159265358979323846264338327950288;

bool exact_integer(double value, int low, int high, int& decoded) noexcept {
    if (!std::isfinite(value) || value < low || value > high || std::trunc(value) != value) return false;
    decoded = static_cast<int>(value);
    return true;
}

double integrate(int function_id, int p) noexcept {
    const double h = 1.0 / static_cast<double>(1 << p);
    const double half_pi = pi / 2.0;
    const int limit = 3 * (1 << p);
    double total = 0.0;
    for (int j = -limit; j <= limit; ++j) {
        const double t = static_cast<double>(j) * h;
        const double exp_t = std::exp(t);
        const double exp_minus_t = std::exp(-t);
        const double sinh_t = (exp_t - exp_minus_t) * 0.5;
        const double cosh_t = (exp_t + exp_minus_t) * 0.5;
        const double u = half_pi * sinh_t;
        const double abs_u = u < 0.0 ? -u : u;
        const double q = std::exp(-2.0 * abs_u);
        const double one_plus_q = 1.0 + q;
        const double sech_squared = (4.0 * q) / (one_plus_q * one_plus_q);
        const double magnitude_x = (1.0 - q) / one_plus_q;
        const double x = u >= 0.0 ? magnitude_x : -magnitude_x;
        const double jacobian = (half_pi * cosh_t) * sech_squared;
        double sample;
        if (function_id == 0) sample = 1.0;
        else if (function_id == 1) sample = x * x;
        else if (function_id == 2) sample = 1.0 / std::sqrt(sech_squared);
        else if (u >= 0.0) sample = 1.0 / std::sqrt((2.0 * q) / one_plus_q);
        else sample = 1.0 / std::sqrt(2.0 / one_plus_q);
        const double transformed = sample * jacobian;
        total += h * transformed;
    }
    return total;
}
}

extern "C" std::int64_t tanh_sinh_double_exponential_quadrature(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 2 || input_length > max_parseable_input_length) return -1;
    int function_id, p;
    if (input_length != 2 || !exact_integer(input[0], 0, 3, function_id)
        || !exact_integer(input[1], 2, 4, p)) return -1;
    if (output == nullptr || output_capacity < 1) return -2;
    const double value = integrate(function_id, p);
    if (!std::isfinite(value)) return -1;
    output[0] = value;
    return 1;
}
