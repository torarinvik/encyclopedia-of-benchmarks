/// Small-amplitude pendulum period: 2 * pi * sqrt(length / g).
const PI: f64 = 3.141592653589793238462643383279502884;

#[no_mangle]
pub extern "C" fn period_of_pendulum(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 1 { return -1.0e300; }
    let pendulum_length = unsafe { *values };
    if !(0..=1000).contains(&pendulum_length) { return -1.0e300; }
    let root = ((pendulum_length as f64) / 9.80665).powf(0.5);
    (2.0 * PI) * root
}
