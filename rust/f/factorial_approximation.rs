#[no_mangle]
pub extern "C" fn factorial_approximation(x: f64) -> f64 {
    if !(x >= 0.0 && x <= 170.0) { return -1.0; }
    3.141592653589793_f64.sqrt() * (x / 2.718281828459045).powf(x)
        * (8.0 * x.powf(3.0) + 4.0 * x.powf(2.0) + x + 1.0 / 30.0).powf(1.0 / 6.0)
}
