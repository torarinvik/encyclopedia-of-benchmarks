const INVALID_RESULT: f64 = -1.0e300;

/// Calculate the generalized combination for a real total and integer choose.
#[no_mangle]
pub extern "C" fn ncr_combinations(total: f64, choose: f64) -> f64 {
    if !total.is_finite() || !choose.is_finite() || !(0.0..=20.0).contains(&total) ||
        !(0.0..=12.0).contains(&choose) || choose.fract() != 0.0 {
        return INVALID_RESULT;
    }

    let count = choose as i64;
    let mut numerator = 1.0;
    for index in 0..count {
        numerator *= total - index as f64;
    }
    let mut denominator = 1.0;
    for factor in 2..=count {
        denominator *= factor as f64;
    }
    numerator / denominator
}
