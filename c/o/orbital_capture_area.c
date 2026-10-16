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

double orbital_capture_area(double capture_radius) {
    if (!(capture_radius >= 0.0 && capture_radius <= 1.0e10)) return INVALID_RESULT;
    const double area = 3.14159265358979323846 * capture_radius * capture_radius;
    return round_nonnegative(area);
}
