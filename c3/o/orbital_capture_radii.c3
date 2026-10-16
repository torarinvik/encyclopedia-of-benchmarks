module orbital_capture_radii;

extern fn double floor(double value);
extern fn double sqrt(double value);

fn double round_nonnegative(double value) {
    if (value >= 9007199254740992.0) return value;
    double lower = floor(value);
    double fraction = value - lower;
    double lower_half = floor(lower / 2.0);
    bool odd = lower - 2.0 * lower_half != 0.0;
    if (fraction > 0.5 || (fraction == 0.5 && odd)) return lower + 1.0;
    return lower;
}

fn double orbital_capture_radii(double radius, double mass, double velocity) @export("orbital_capture_radii") {
    if (!(radius >= 1.0e-6 && radius <= 1.0e10) || !(mass >= 0.0 && mass <= 2.0e30) || !(velocity >= 1.0e6 && velocity <= 299792458.0)) return -1.0e300;
    double escape_velocity_squared = (2.0 * 6.67430e-11 * mass) / radius;
    double capture_radius = radius * sqrt(1.0 + escape_velocity_squared / (velocity * velocity));
    return round_nonnegative(capture_radius);
}
