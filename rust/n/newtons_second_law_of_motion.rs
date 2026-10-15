/// Newton's second law: net force equals mass times acceleration.
#[no_mangle]
pub extern "C" fn newtons_second_law_of_motion(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return -1.0e300; }
    let mass = unsafe { *values };
    let acceleration = unsafe { *values.add(1) };
    if !(-1000..=1000).contains(&mass) || !(-1000..=1000).contains(&acceleration) {
        return -1.0e300;
    }
    (mass as f64) * (acceleration as f64)
}
