#[no_mangle]
pub extern "C" fn cos(x_value: f64) -> f64 {
    if !(x_value >= -1_000_000.0 && x_value <= 1_000_000.0) {
        return -1.0;
    }
    let tp = 1.0 / (2.0 * 3.141592653589793);
    let mut x = x_value * tp;
    x -= 0.25 + (x + 0.25).floor();
    x *= 16.0 * (x.abs() - 0.5);
    x += 0.225 * x * (x.abs() - 1.0);
    x
}
