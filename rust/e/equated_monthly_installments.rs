const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn equated_monthly_installments(principal: f64, rate_per_annum: f64, years_to_repay: f64) -> f64 {
    if !principal.is_finite() || !rate_per_annum.is_finite() || !years_to_repay.is_finite() ||
        principal <= 0.0 || principal > 1_000_000.0 || rate_per_annum < 0.0001 || rate_per_annum > 0.2 ||
        years_to_repay < 1.0 || years_to_repay > 30.0 || years_to_repay.fract() != 0.0 {
        return INVALID_RESULT;
    }
    let monthly_rate = rate_per_annum / 12.0;
    let payments = years_to_repay * 12.0;
    let factor = (1.0 + monthly_rate).powf(payments);
    principal * monthly_rate * factor / (factor - 1.0)
}
