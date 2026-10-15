/// Malus's law: I0 * cos(radians(angle))^2.
const PI: f64 = 3.141592653589793238462643383279502884;

#[no_mangle]
pub extern "C" fn malus_law(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let initial_intensity = unsafe { *values };
    let angle = unsafe { *values.add(1) };
    if !(0..=1000).contains(&initial_intensity) || !(0..=360).contains(&angle) {
        return -1.0e300;
    }
    let radians = ((angle as f64) * PI) / 180.0;
    let cosine = radians.cos();
    (initial_intensity as f64) * (cosine * cosine)
}
