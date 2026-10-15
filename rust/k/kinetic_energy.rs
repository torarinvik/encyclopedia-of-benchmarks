/// Classical kinetic energy: 0.5 * mass * abs(velocity)^2.
#[no_mangle]
pub extern "C" fn kinetic_energy(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let mass = unsafe { *values };
    let velocity = unsafe { *values.add(1) };
    if !(0..=1000).contains(&mass) || !(-1000..=1000).contains(&velocity) {
        return -1.0e300;
    }
    let speed = if velocity < 0 { -velocity } else { velocity };
    ((0.5 * (mass as f64)) * (speed as f64)) * (speed as f64)
}
