// Return one component of the Cartesian-to-polar transformation.
#include <cmath>

extern "C" double cartesian_to_polar(double x, double y, double component) noexcept {
    if (x != x || y != y || (component != 0.0 && component != 1.0) ||
        x < -1000000.0 || x > 1000000.0 || y < -1000000.0 || y > 1000000.0) {
        return -1.0e300;
    }
    if (component == 0.0) return std::sqrt(x * x + y * y);
    if (x == 0.0 && y == 0.0) return 0.0;
    return std::atan2(y, x);
}
