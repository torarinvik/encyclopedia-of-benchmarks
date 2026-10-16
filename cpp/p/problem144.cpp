#include <cmath>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr int MAX_REFLECTIONS = 10000;

bool is_close(double left, double right) noexcept
{
    const double scale = std::fmax(std::fabs(left), std::fabs(right));
    return std::fabs(left - right) <= 1.0e-9 * scale;
}

struct Ray_Point { double x; double y; double gradient; };

Ray_Point next_point(double point_x, double point_y, double incoming_gradient) noexcept
{
    const double normal_gradient = point_y / 4.0 / point_x;
    const double s2 = 2.0 * normal_gradient / (1.0 + normal_gradient * normal_gradient);
    const double c2 = (1.0 - normal_gradient * normal_gradient) /
                      (1.0 + normal_gradient * normal_gradient);
    const double outgoing_gradient = (s2 - c2 * incoming_gradient) /
                                     (c2 + s2 * incoming_gradient);
    const double quadratic_term = outgoing_gradient * outgoing_gradient + 4.0;
    const double line_offset = point_y - outgoing_gradient * point_x;
    const double linear_term = 2.0 * outgoing_gradient * line_offset;
    const double constant_term = line_offset * line_offset - 100.0;
    const double root = std::sqrt(linear_term * linear_term -
                                  4.0 * quadratic_term * constant_term);
    const double x_minus = (-linear_term - root) / (2.0 * quadratic_term);
    const double x_plus = (-linear_term + root) / (2.0 * quadratic_term);
    const double next_x = is_close(x_plus, point_x) ? x_minus : x_plus;
    return {next_x, point_y + outgoing_gradient * (next_x - point_x), outgoing_gradient};
}
}

extern "C" double problem144(double first_x_coord, double first_y_coord) noexcept
{
    if (std::isnan(first_x_coord) || std::isnan(first_y_coord) ||
        first_x_coord < 1.0e-5 || first_x_coord > 5.0 ||
        first_y_coord < -10.0 || first_y_coord > 0.0) return INVALID_RESULT;
    const double ellipse_residual = 4.0 * first_x_coord * first_x_coord +
                                    first_y_coord * first_y_coord - 100.0;
    if (std::fabs(ellipse_residual) > 1.0e-6) return INVALID_RESULT;

    double point_x = first_x_coord;
    double point_y = first_y_coord;
    double gradient = (10.1 - point_y) / (0.0 - point_x);
    int reflections = 0;
    while (!(point_x >= -0.01 && point_x <= 0.01 && point_y > 0.0)) {
        if (reflections >= MAX_REFLECTIONS) return INVALID_RESULT;
        const Ray_Point next = next_point(point_x, point_y, gradient);
        if (std::isnan(next.x) || std::isnan(next.y)) return INVALID_RESULT;
        point_x = next.x;
        point_y = next.y;
        gradient = next.gradient;
        ++reflections;
    }
    return static_cast<double>(reflections);
}
