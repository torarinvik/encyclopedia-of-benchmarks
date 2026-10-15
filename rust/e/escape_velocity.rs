/// Escape velocity with the source's three-decimal result rounding.
fn round_three_even(value: f64) -> f64 {
    let scaled = value * 1000.0;
    let lower = scaled.floor();
    let midpoint = lower + 0.5;
    let exact_side = value.mul_add(1000.0, -midpoint);
    let mut rounded = lower as i64;
    if exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0) {
        rounded += 1;
    }
    rounded as f64 / 1000.0
}

#[no_mangle]
pub extern "C" fn escape_velocity(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let (mass, radius) = unsafe { (*values, *values.add(1)) };
    if !(0..=1_000_000_000_000_000).contains(&mass) || !(1..=1_000_000_000).contains(&radius) {
        return -1.0e300;
    }
    let velocity = (2.0 * 6.67430e-11 * mass as f64 / radius as f64).sqrt();
    round_three_even(velocity)
}
