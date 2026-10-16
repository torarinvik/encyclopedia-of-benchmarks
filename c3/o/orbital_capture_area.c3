module orbital_capture_area;

extern fn double floor(double value);

fn double round_nonnegative(double value) {
    if (value >= 9007199254740992.0) return value;
    double lower = floor(value);
    double fraction = value - lower;
    double lower_half = floor(lower / 2.0);
    bool odd = lower - 2.0 * lower_half != 0.0;
    if (fraction > 0.5 || (fraction == 0.5 && odd)) return lower + 1.0;
    return lower;
}

fn double orbital_capture_area(double capture_radius) @export("orbital_capture_area") {
    if (!(capture_radius >= 0.0 && capture_radius <= 1.0e10)) return -1.0e300;
    double area = 3.14159265358979323846 * capture_radius * capture_radius;
    return round_nonnegative(area);
}
