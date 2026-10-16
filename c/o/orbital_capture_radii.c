#include <math.h>

#define INVALID_RESULT (-1.0e300)

static double round_nonnegative(double value) {
    if (value >= 9007199254740992.0) return value;
    const double lower = floor(value);
    const double fraction = value - lower;
    const double lower_half = floor(lower / 2.0);
    const int odd = lower - 2.0 * lower_half != 0.0;
    if (fraction > 0.5 || (fraction == 0.5 && odd)) return lower + 1.0;
    return lower;
}

double orbital_capture_radii(double radius, double mass, double velocity) {
    if (!(radius >= 1.0e-6 && radius <= 1.0e10) ||
        !(mass >= 0.0 && mass <= 2.0e30) ||
        !(velocity >= 1.0e6 && velocity <= 299792458.0)) return INVALID_RESULT;
    const double escape_velocity_squared = (2.0 * 6.67430e-11 * mass) / radius;
    const double capture_radius = radius * sqrt(1.0 + escape_velocity_squared / (velocity * velocity));
    return round_nonnegative(capture_radius);
}
