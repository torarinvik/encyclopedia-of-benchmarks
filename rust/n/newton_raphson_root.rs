#[no_mangle]
pub extern "C" fn newton_raphson_root(x0: f64) -> f64 {
    if !x0.is_finite() || !(1.0..=4.0).contains(&x0) {
        return -1e300;
    }
    let mut x = x0 as f32;
    for _ in 0..1000 {
        let square: f32 = x * x;
        let residual: f32 = square - 3.0_f32;
        if residual.abs() <= 1e-6_f32 {
            return f64::from(x);
        }
        let derivative: f32 = 2.0_f32 * x;
        if derivative == 0.0 {
            return -1e300;
        }
        let quotient: f32 = residual / derivative;
        x = x - quotient;
    }
    f64::from(x)
}
