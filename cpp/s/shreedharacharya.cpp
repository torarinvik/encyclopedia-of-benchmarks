#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double max_coefficient = 1'000'000.0;
constexpr double min_abs_leading_coefficient = 0.000001;
}

extern "C" std::int64_t shreedharacharya(const double *input, std::size_t input_length,
                                         double *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length != 3) return -1;
    const double a = input[0], b = input[1], c = input[2];
    if (!std::isfinite(a) || !std::isfinite(b) || !std::isfinite(c) ||
        std::abs(a) < min_abs_leading_coefficient || std::abs(a) > max_coefficient ||
        std::abs(b) > max_coefficient || std::abs(c) > max_coefficient) return -1;

    const double discriminant = b * b - 4.0 * a * c;
    double roots[2];
    std::size_t count = 0;
    if (discriminant == 0.0) {
        roots[count++] = -b / (2.0 * a);
    } else if (discriminant > 0.0) {
        const double square_root = std::sqrt(discriminant);
        const double denominator = 2.0 * a;
        roots[count++] = (-b + square_root) / denominator;
        roots[count++] = (-b - square_root) / denominator;
    }
    for (std::size_t index = 0; index < count; ++index)
        if (!std::isfinite(roots[index])) return -1;
    if (output == nullptr || output_capacity < count) return -2;
    for (std::size_t index = 0; index < count; ++index) output[index] = roots[index];
    return static_cast<std::int64_t>(count);
}
