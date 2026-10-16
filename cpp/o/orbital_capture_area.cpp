#include <cmath>

static double round_nonnegative(double value) {
    if (value >= 9007199254740992.0) return value;
    const double lower = std::floor(value);
    const double fraction = value - lower;
    const double lower_half = std::floor(lower / 2.0);
    const bool odd = lower - 2.0 * lower_half != 0.0;
    if (fraction > 0.5 || (fraction == 0.5 && odd)) return lower + 1.0;
    return lower;
}

extern "C" double orbital_capture_area(double capture_radius) noexcept {
    if (!(capture_radius >= 0.0 && capture_radius <= 1.0e10)) return -1.0e300;
    const double area = 3.14159265358979323846 * capture_radius * capture_radius;
    return round_nonnegative(area);
}
