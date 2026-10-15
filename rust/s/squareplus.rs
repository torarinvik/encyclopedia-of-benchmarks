/// Squareplus activation for one element of the source vector.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn squareplus(x: f64, beta: f64) -> f64 {
    if !x.is_finite() || !beta.is_finite() || x < -10000.0 || x > 10000.0 || beta < 0.25 || beta > 10000.0 {
        return INVALID_RESULT;
    }
    (x + (x * x + beta).sqrt()) / 2.0
}
