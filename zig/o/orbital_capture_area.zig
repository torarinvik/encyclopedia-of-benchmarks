/// Circular cross-sectional area for orbital capture, rounded to whole square metres.
fn roundNonnegative(value: f64) f64 {
    if (value >= 9007199254740992.0) return value;
    const lower = @floor(value);
    const fraction = value - lower;
    const lower_half = @floor(lower / 2.0);
    const odd = lower - 2.0 * lower_half != 0.0;
    if (fraction > 0.5 or (fraction == 0.5 and odd)) return lower + 1.0;
    return lower;
}

pub export fn orbital_capture_area(capture_radius: f64) f64 {
    if (!(capture_radius >= 0.0 and capture_radius <= 1.0e10)) return -1.0e300;
    const area = 3.14159265358979323846 * capture_radius * capture_radius;
    return roundNonnegative(area);
}
