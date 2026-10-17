#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_sample_count = 1;
constexpr std::size_t max_sample_count = 32;
constexpr std::size_t max_parseable_input_length = 38;

bool finite_value(double value)
{
    return std::isfinite(value);
}
}

extern "C" std::int64_t soboleva_modified_hyperbolic_tangent(
    const double *input, std::size_t input_length, double *output,
    std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 5 || input_length > max_parseable_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i) {
        if (!finite_value(input[i])) return -1;
    }

    const double count_value = input[0];
    if (count_value < static_cast<double>(min_sample_count) ||
        count_value > static_cast<double>(max_sample_count)) return -1;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (count_value != static_cast<double>(count) || input_length != 5 + count) return -1;

    const double a = input[1], b = input[2], c = input[3], d = input[4];
    if (a < -2.0 || a > 2.0 || b < -2.0 || b > 2.0 ||
        c < -2.0 || c > 2.0 || d < -2.0 || d > 2.0) return -1;
    for (std::size_t i = 0; i < count; ++i) {
        if (input[5 + i] < -20.0 || input[5 + i] > 20.0) return -1;
    }

    if (output == nullptr || output_capacity < count) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        const double x = input[5 + i];
        const double ax = a * x;
        const double neg_b_x = (-b) * x;
        const double cx = c * x;
        const double neg_d_x = (-d) * x;
        const double numerator = std::exp(ax) - std::exp(neg_b_x);
        const double denominator = std::exp(cx) + std::exp(neg_d_x);
        output[i] = numerator / denominator;
    }
    return static_cast<std::int64_t>(count);
}
