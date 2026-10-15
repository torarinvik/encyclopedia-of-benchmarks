const INVALID_RESULT: f64 = -1.0e300;
const HALF_PI: f64 = 1.5707963267948966;

#[no_mangle]
pub extern "C" fn snell_law(n1: f64, n2: f64, theta1: f64) -> f64 {
    if !n1.is_finite() || !n2.is_finite() || !theta1.is_finite() ||
        n1 < 0.5 || n1 > 2.5 || n2 < 0.5 || n2 > 2.5 || theta1 < -HALF_PI || theta1 > HALF_PI
    {
        return INVALID_RESULT;
    }
    let ratio = n1 / n2;
    let sin_theta2 = ratio * theta1.sin();
    if sin_theta2.abs() > 1.0 {
        return INVALID_RESULT;
    }
    sin_theta2.asin()
}
