/* Find a root of one of two documented cubics by interval bisection. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_coord_milli = 100000;
constexpr std::int64_t max_tolerance_micro = 1000000;
constexpr double root_scale = 1000000.0;
constexpr int max_iterations = 64;
double evaluate(std::int64_t equation, double x) noexcept {
    return equation == 0 ? x * x * x + 2.0 * x - 10.0 : x * x * x - 4.0 * x - 9.0;
}
}

extern "C" std::int64_t bisection_method(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 4) return -1;
    const auto equation = input[0], left_milli = input[1], right_milli = input[2], tolerance_micro = input[3];
    if (equation < 0 || equation > 1 || left_milli < -max_coord_milli || left_milli > max_coord_milli ||
        right_milli < -max_coord_milli || right_milli > max_coord_milli || left_milli >= right_milli ||
        tolerance_micro < 1 || tolerance_micro > max_tolerance_micro) return -1;
    double left = static_cast<double>(left_milli) / 1000.0;
    double right = static_cast<double>(right_milli) / 1000.0;
    double f_left = evaluate(equation, left);
    const double f_right = evaluate(equation, right);
    if (f_left == 0.0) return static_cast<std::int64_t>(left * root_scale + 0.5);
    if (f_right == 0.0) return static_cast<std::int64_t>(right * root_scale + 0.5);
    if ((f_left < 0.0) == (f_right < 0.0)) return -2;
    const double tolerance = static_cast<double>(tolerance_micro) / root_scale;
    for (int iteration = 0; iteration < max_iterations; ++iteration) {
        const double middle = left + (right - left) * 0.5;
        const double f_middle = evaluate(equation, middle);
        if (f_middle == 0.0) return static_cast<std::int64_t>(middle * root_scale + 0.5);
        if ((f_left < 0.0) != (f_middle < 0.0)) right = middle;
        else { left = middle; f_left = f_middle; }
        if (right - left <= tolerance)
            return static_cast<std::int64_t>((left + (right - left) * 0.5) * root_scale + 0.5);
    }
    return -2;
}
