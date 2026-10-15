/// Gravitational potential energy: mass * standard gravity * height.
#[no_mangle]
pub extern "C" fn potential_energy(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let mass = unsafe { *values };
    let height = unsafe { *values.add(1) };
    if !(0..=1000).contains(&mass) || !(0..=1000).contains(&height) {
        return -1.0e300;
    }
    ((mass as f64) * 9.80665) * (height as f64)
}
