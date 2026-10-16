#include <cmath>

namespace { constexpr double invalid_result = -1e300; }

// Repeated-step polyline length for the source demo curve sin(10*x).
extern "C" double line_length(double x_start, double x_end, double steps_value) noexcept
{
    if (x_start != x_start || x_end != x_end || steps_value != steps_value ||
        x_start < -10.0 || x_start > 10.0 || x_end < -10.0 || x_end > 10.0 ||
        x_start > x_end || steps_value < 1.0 || steps_value > 10000.0) {
        return invalid_result;
    }
    const int steps = static_cast<int>(steps_value);
    if (static_cast<double>(steps) != steps_value) return invalid_result;

    double x1 = x_start;
    double fx1 = std::sin(10.0 * x_start);
    double length = 0.0;
    for (int index = 0; index < steps; ++index) {
        const double x2 = (x_end - x_start) / steps + x1;
        const double fx2 = std::sin(10.0 * x2);
        const double dx = x2 - x1;
        const double dy = fx2 - fx1;
        length += std::sqrt(dx * dx + dy * dy);
        x1 = x2;
        fx1 = fx2;
    }
    return length;
}
