const INVALID_RESULT: f64 = -1.0e300;
const PI: f64 = 3.14159265358979323846264338327950288;

#[no_mangle]
pub extern "C" fn gaussian(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let x = unsafe { *values };
    let mu = unsafe { *values.add(1) };
    let sigma = unsafe { *values.add(2) };
    if !(-100..=100).contains(&x) || !(-100..=100).contains(&mu) || !(1..=100).contains(&sigma) { return INVALID_RESULT; }
    let difference = x - mu;
    let sigma_squared = sigma * sigma;
    let normalization = 1.0 / (2.0 * PI * sigma_squared as f64).sqrt();
    let exponent = -((difference * difference) as f64) / (2 * sigma_squared) as f64;
    normalization * exponent.exp()
}
