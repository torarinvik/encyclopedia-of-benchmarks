/// Orbital capture radius from the pinned gravitational-focusing formula.
fn roundNonnegative(value: f64) f64 {
    if (value >= 9007199254740992.0) return value;
    const lower = @floor(value);
    const fraction = value - lower;
    const lower_half = @floor(lower / 2.0);
    const odd = lower - 2.0 * lower_half != 0.0;
    if (fraction > 0.5 or (fraction == 0.5 and odd)) return lower + 1.0;
    return lower;
}

pub export fn orbital_capture_radii(radius: f64, mass: f64, velocity: f64) f64 {
    if (!(radius >= 1.0e-6 and radius <= 1.0e10) or !(mass >= 0.0 and mass <= 2.0e30) or !(velocity >= 1.0e6 and velocity <= 299792458.0)) return -1.0e300;
    const escape_velocity_squared = (2.0 * 6.67430e-11 * mass) / radius;
    const capture_radius = radius * @sqrt(1.0 + escape_velocity_squared / (velocity * velocity));
    return roundNonnegative(capture_radius);
}
