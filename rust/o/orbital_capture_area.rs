/// Circular cross-sectional area for orbital capture, rounded to whole square metres.
fn round_nonnegative(value: f64) -> f64 {
    if value >= 9_007_199_254_740_992.0 { return value; }
    let lower = value.floor();
    let fraction = value - lower;
    let lower_half = (lower / 2.0).floor();
    let odd = lower - 2.0 * lower_half != 0.0;
    if fraction > 0.5 || (fraction == 0.5 && odd) { lower + 1.0 } else { lower }
}

#[no_mangle]
pub extern "C" fn orbital_capture_area(capture_radius: f64) -> f64 {
    if !(0.0..=1.0e10).contains(&capture_radius) { return -1.0e300; }
    let area = 3.14159265358979323846 * capture_radius * capture_radius;
    round_nonnegative(area)
}
