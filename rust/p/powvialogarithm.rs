/// Power through the pinned logarithm/exponential method.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn powvialogarithm(base: f64, exponent: f64) -> f64 {
    if !base.is_finite() || !exponent.is_finite() || !(-4.0..=4.0).contains(&base)
        || !(-8.0..=8.0).contains(&exponent) || base.trunc() != base || exponent.trunc() != exponent
        || (base == 0.0 && exponent <= 0.0)
        || ((base == 2.0 || base == -2.0) && exponent == -1.0) {
        return INVALID_RESULT;
    }

    let mut sign = 1.0;
    let power = exponent as i64;
    if base < 0.0 && power % 2 != 0 { sign = -1.0; }
    let logarithm = base.abs().ln();
    let exponential = (exponent * logarithm).exp();
    let result = exponential * sign;
    result.round()
}
