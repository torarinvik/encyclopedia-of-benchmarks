/// Orbital capture radius from the pinned gravitational-focusing formula.
fn round_nonnegative(value: f64) -> f64 {
    if value >= 9_007_199_254_740_992.0 { return value; }
    let lower = value.floor();
    let fraction = value - lower;
    let lower_half = (lower / 2.0).floor();
    let odd = lower - 2.0 * lower_half != 0.0;
    if fraction > 0.5 || (fraction == 0.5 && odd) { lower + 1.0 } else { lower }
}

#[no_mangle]
pub extern "C" fn orbital_capture_radii(radius: f64, mass: f64, velocity: f64) -> f64 {
    if !(1.0e-6..=1.0e10).contains(&radius) || !(0.0..=2.0e30).contains(&mass) || !(1.0e6..=299792458.0).contains(&velocity) { return -1.0e300; }
    let escape_velocity_squared = (2.0 * 6.67430e-11 * mass) / radius;
    let capture_radius = radius * (1.0 + escape_velocity_squared / (velocity * velocity)).sqrt();
    round_nonnegative(capture_radius)
}
