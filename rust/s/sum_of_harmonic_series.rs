const INVALID_RESULT: f64 = -1.0e300;
#[no_mangle]
pub extern "C" fn sum_of_harmonic_series(first_term: f64, common_difference: f64, number_of_terms: f64) -> f64 {
    if !first_term.is_finite() || !common_difference.is_finite() || !number_of_terms.is_finite() ||
        first_term <= 0.0 || first_term > 1000.0 || common_difference < 0.0 || common_difference > 1000.0 ||
        number_of_terms < 1.0 || number_of_terms > 256.0 || number_of_terms.fract() != 0.0 { return INVALID_RESULT; }
    let count = number_of_terms as i32;
    let mut arithmetic_term = 1.0 / first_term;
    let mut total = 0.0;
    for index in 0..count {
        total += 1.0 / arithmetic_term;
        if index + 1 < count { arithmetic_term += common_difference; }
    }
    total
}
