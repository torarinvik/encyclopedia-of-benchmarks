/// Hooke's law restoring force: -spring_constant * displacement.
#[no_mangle]
pub extern "C" fn hookes_law(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let spring_constant = unsafe { *values };
    let displacement = unsafe { *values.add(1) };
    if !(1..=1000).contains(&spring_constant) || !(-1000..=1000).contains(&displacement) {
        return -1.0e300;
    }
    (-(spring_constant as f64)) * (displacement as f64)
}
