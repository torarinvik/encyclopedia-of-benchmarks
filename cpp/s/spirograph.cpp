/* Generate bounded, interleaved spirograph coordinates. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_points = 32;
constexpr std::size_t max_parseable_input_length = 5;
constexpr std::size_t max_output_elements = 64;

bool exact_point_count(double value, std::size_t& point_count) noexcept {
    if (!std::isfinite(value) || value < 1.0 || value > static_cast<double>(max_points)) return false;
    const auto converted = static_cast<int>(value);
    if (static_cast<double>(converted) != value) return false;
    point_count = static_cast<std::size_t>(converted);
    return true;
}
}

extern "C" std::int64_t spirograph(const double* input, std::size_t input_length,
                                   double* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 || input_length > max_parseable_input_length ||
        input_length != 4) return -1;

    std::size_t point_count;
    if (!exact_point_count(input[0], point_count)) return -1;
    const double marker_ratio = input[1];
    const double inner_ratio = input[2];
    const double rotations = input[3];
    if (!std::isfinite(marker_ratio) || marker_ratio < 0.0 || marker_ratio > 1.0 ||
        !std::isfinite(inner_ratio) || inner_ratio < 0.25 || inner_ratio > 0.75 ||
        !std::isfinite(rotations) || rotations < 0.0 || rotations > 10.0) return -1;

    constexpr double pi = 3.141592653589793238462643383279502884;
    const double delta = rotations * 2.0 * pi / static_cast<double>(point_count);
    const double outer_ratio = 1.0 - inner_ratio;
    const double marker_radius = marker_ratio * inner_ratio;
    double staged[max_output_elements]{};
    for (std::size_t index = 0; index < point_count; ++index) {
        const double t = delta * static_cast<double>(index);
        const double inner_angle = outer_ratio * t / inner_ratio;
        const double x = outer_ratio * std::cos(t) + marker_radius * std::cos(inner_angle);
        const double y = outer_ratio * std::sin(t) - marker_radius * std::sin(inner_angle);
        if (!std::isfinite(x) || !std::isfinite(y)) return -1;
        staged[2 * index] = x;
        staged[2 * index + 1] = y;
    }

    const std::size_t output_length = 2 * point_count;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_length);
}
