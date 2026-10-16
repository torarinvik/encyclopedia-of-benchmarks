const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn sigmoid_without_inbuilt(x: f64, slope: f64) -> f64 {
    if !x.is_finite() || !slope.is_finite() || x < -10.0 || x > 10.0
        || slope < -10.0 || slope > 10.0 {
        return INVALID_RESULT;
    }
    1.0 / (1.0 + (-slope * x).exp())
}

