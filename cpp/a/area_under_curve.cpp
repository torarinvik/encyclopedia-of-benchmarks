/* Composite trapezoidal integration for three bounded sample functions. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_steps = 10000;
constexpr std::int64_t max_coord_milli = 100000;
constexpr double output_scale = 1000000.0;
double sample_value(std::int64_t function_id, double x) noexcept {
    if (function_id == 0) return 5.0;
    if (function_id == 1) return x;
    return x * x;
}
}

extern "C" std::int64_t area_under_curve(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 4) return -1;
    const auto function_id = input[0], start_milli = input[1], end_milli = input[2], steps = input[3];
    if (function_id < 0 || function_id > 2 || start_milli < 0 || start_milli > max_coord_milli ||
        end_milli < 0 || end_milli > max_coord_milli || steps < 1 || steps > max_steps) return -1;
    const auto low_milli = start_milli < end_milli ? start_milli : end_milli;
    const auto high_milli = start_milli < end_milli ? end_milli : start_milli;
    const double start = static_cast<double>(low_milli) / 1000.0;
    const double end = static_cast<double>(high_milli) / 1000.0;
    const double width = (end - start) / static_cast<double>(steps);
    double x1 = start;
    double y1 = sample_value(function_id, x1);
    double area = 0.0;
    for (std::int64_t index = 0; index < steps; ++index) {
        const double x2 = x1 + width;
        const double y2 = sample_value(function_id, x2);
        area += (y1 + y2) * width * 0.5;
        x1 = x2;
        y1 = y2;
    }
    return static_cast<std::int64_t>(area * output_scale + 0.5);
}
