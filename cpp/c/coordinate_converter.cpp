#include <cmath>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr double coordinate_limit = 1000000.0;
constexpr double angle_limit_degrees = 36000.0;
constexpr double degrees_per_radian = 57.2957795130823208768;
constexpr double radians_per_degree = 0.0174532925199432957692;
}

extern "C" double coordinate_converter(double first, double second, double component) noexcept {
    if (component == 0.0 || component == 1.0) {
        if (!std::isfinite(first) || !std::isfinite(second) ||
            first < -coordinate_limit || first > coordinate_limit ||
            second < -coordinate_limit || second > coordinate_limit) return invalid_result;
        if (component == 0.0) return std::sqrt(first * first + second * second);
        return std::atan2(second, first) * degrees_per_radian;
    }
    if (component == 2.0 || component == 3.0) {
        if (!std::isfinite(first) || !std::isfinite(second) || first < 0.0 ||
            first > coordinate_limit || second < -angle_limit_degrees ||
            second > angle_limit_degrees) return invalid_result;
        const double radians = second * radians_per_degree;
        return first * (component == 2.0 ? std::cos(radians) : std::sin(radians));
    }
    return invalid_result;
}
