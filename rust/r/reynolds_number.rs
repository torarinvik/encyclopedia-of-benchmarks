/// Reynolds number: density * abs(velocity) * diameter / viscosity.
#[no_mangle]
pub extern "C" fn reynolds_number(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 { return -1.0e300; }
    let density = unsafe { *values };
    let velocity = unsafe { *values.add(1) };
    let diameter = unsafe { *values.add(2) };
    let viscosity = unsafe { *values.add(3) };
    if !(1..=1000).contains(&density) || !(-1000..=1000).contains(&velocity) ||
        !(1..=1000).contains(&diameter) || !(1..=1000).contains(&viscosity) {
        return -1.0e300;
    }
    let speed = if velocity < 0 { -velocity } else { velocity };
    (((density as f64 * speed as f64) * diameter as f64) / viscosity as f64)
}
