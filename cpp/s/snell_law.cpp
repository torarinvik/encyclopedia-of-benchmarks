#include <cmath>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr double half_pi = 1.5707963267948966;
}

extern "C" double snell_law(double n1, double n2, double theta1) noexcept
{
    if (!std::isfinite(n1) || !std::isfinite(n2) || !std::isfinite(theta1) ||
        n1 < 0.5 || n1 > 2.5 || n2 < 0.5 || n2 > 2.5 ||
        theta1 < -half_pi || theta1 > half_pi) return invalid_result;
    const double ratio = n1 / n2;
    const double sin_theta2 = ratio * std::sin(theta1);
    if (std::abs(sin_theta2) > 1.0) return invalid_result;
    return std::asin(sin_theta2);
}
