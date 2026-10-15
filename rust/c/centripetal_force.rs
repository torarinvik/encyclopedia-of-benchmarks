/// Centripetal force: (mass * velocity^2) / radius.
#[no_mangle]
pub extern "C" fn centripetal_force(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return -1.0e300; }
    let mass = unsafe { *values };
    let velocity = unsafe { *values.add(1) };
    let radius = unsafe { *values.add(2) };
    if mass < 0 || mass > 1000 || !(-1000..=1000).contains(&velocity) || !(1..=1000).contains(&radius) {
        return -1.0e300;
    }
    let velocity_squared = (velocity as f64) * (velocity as f64);
    ((mass as f64) * velocity_squared) / (radius as f64)
}
