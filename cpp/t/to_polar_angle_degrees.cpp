/* Match the pinned MATLAB to_polar angle formula in degrees. */
#include <cmath>

extern "C" double to_polar_angle_degrees(double x, double y) noexcept
{
    constexpr double INVALID_RESULT = -1.0e300;
    constexpr double PI = 3.141592653589793238462643383279502884;
    if (x != x || y != y || x < -1000000.0 || x > 1000000.0 ||
        y < -1000000.0 || y > 1000000.0 || (x == 0.0 && y == 0.0)) {
        return INVALID_RESULT;
    }
    const double theta = x >= 0.0 ? std::atan(y / x) : std::atan(y / x) + PI;
    return theta * (180.0 / PI);
}
