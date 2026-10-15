/// Terminal velocity with standard gravity and bounded positive inputs.
#[no_mangle]
pub extern "C" fn terminal_velocity(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return -1.0e300; }
    let mass = unsafe { *values };
    let density = unsafe { *values.add(1) };
    let area = unsafe { *values.add(2) };
    let drag_coefficient = unsafe { *values.add(3) };
    if !(1..=1000).contains(&mass) || !(1..=1000).contains(&density) ||
        !(1..=1000).contains(&area) || !(1..=1000).contains(&drag_coefficient) {
        return -1.0e300;
    }
    let numerator = (2.0 * (mass as f64)) * 9.80665;
    let denominator = ((density as f64) * (area as f64)) * (drag_coefficient as f64);
    (numerator / denominator).sqrt()
}
