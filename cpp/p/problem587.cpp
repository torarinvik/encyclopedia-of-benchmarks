#include <cmath>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr double MIN_FRACTION = 0.001;
constexpr double MAX_FRACTION = 0.1;
constexpr int MAX_N = 100000;
constexpr double PI_VALUE = 3.141592653589793238462643383279502884;

double circle_bottom_arc_integral(double point) noexcept
{
    return ((1.0 - 2.0 * point) * std::sqrt(point - point * point) +
            2.0 * point + std::asin(std::sqrt(1.0 - point))) / 4.0;
}

double concave_triangle_area(int n) noexcept
{
    const double circles = static_cast<double>(n);
    const double intersection_y = (circles + 1.0 - std::sqrt(2.0 * circles)) /
                                  (2.0 * (circles * circles + 1.0));
    const double intersection_x = circles * intersection_y;
    const double triangle_area = intersection_x * intersection_y / 2.0;
    const double concave_region_area = circle_bottom_arc_integral(0.5) -
                                       circle_bottom_arc_integral(intersection_x);
    return triangle_area + concave_region_area;
}
}

extern "C" double problem587(double fraction) noexcept
{
    if (std::isnan(fraction) || fraction < MIN_FRACTION || fraction > MAX_FRACTION)
        return INVALID_RESULT;
    const double l_section_area = (1.0 - PI_VALUE / 4.0) / 4.0;
    for (int n = 1; n <= MAX_N; ++n) {
        if (concave_triangle_area(n) / l_section_area < fraction) return static_cast<double>(n);
    }
    return INVALID_RESULT;
}
