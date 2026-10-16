// Perimeter and area calculations for a bounded circle radius.
#include <cmath>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr double pi = 3.14159265358979323846;
}

extern "C" double circle(double radius, double operation) noexcept {
    if (!(std::isfinite(radius) && std::isfinite(operation) &&
          radius >= -1000000.0 && radius <= 1000000.0 &&
          (operation == 0.0 || operation == 1.0))) return invalid_result;
    if (operation == 0.0) return radius * 2.0 * pi;
    return std::pow(radius, 2.0) * pi;
}
