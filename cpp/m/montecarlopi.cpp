#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_random_points = 1;
constexpr std::size_t max_random_points = 64;
constexpr std::size_t max_input_length = 130;

bool finite_value(double value) noexcept { return std::isfinite(value); }

bool exact_sample_count(double value, std::size_t& count) noexcept
{
    if (!finite_value(value) || value < static_cast<double>(min_random_points) ||
        value > static_cast<double>(max_random_points) || std::trunc(value) != value) return false;
    count = static_cast<std::size_t>(value);
    return true;
}

double rounded_divide(double numerator, double denominator) noexcept
{
    volatile double result = numerator / denominator;
    return result;
}

double rounded_multiply(double left, double right) noexcept
{
    volatile double result = left * right;
    return result;
}

bool allowed_coordinate(double value) noexcept
{
    return value == 0.0 || value == 0.25 || value == 0.5 || value == 0.75;
}
} // namespace

extern "C" std::int64_t montecarlopi(const double* values, std::size_t length,
                                     double* output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 3 || length > max_input_length) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (!finite_value(values[index])) return -1;

    std::size_t random_points;
    if (!exact_sample_count(values[0], random_points) ||
        length != 1 + 2 * random_points) return -1;

    std::size_t inside = 0;
    for (std::size_t index = 0; index < random_points; ++index) {
        const double x = values[1 + 2 * index];
        const double y = values[2 + 2 * index];
        if (!allowed_coordinate(x) || !allowed_coordinate(y)) return -1;
        const double x_squared = rounded_multiply(x, x);
        const double y_squared = rounded_multiply(y, y);
        const double squared_radius = x_squared + y_squared;
        if (squared_radius <= 1.0) ++inside;
    }

    const double fraction = rounded_divide(static_cast<double>(inside),
                                           static_cast<double>(random_points));
    const double estimate = rounded_multiply(fraction, 4.0);
    if (!finite_value(estimate)) return -1;

    if (output == nullptr || output_capacity < 1) return -2;
    output[0] = estimate;
    return 1;
}
