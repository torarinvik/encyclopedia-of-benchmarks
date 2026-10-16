/// Cross-platform scalar implementation of earnings_per_sale.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn earnings_per_sale(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let net_income = *values.add(0);
    let preferred_dividend = *values.add(1);
    let average_shares = *values.add(2);
    if net_income < -1000000 || net_income > 1000000 || preferred_dividend < 0 || preferred_dividend > 1000000 || average_shares < 1 || average_shares > 1000000 { return INVALID_RESULT; }
    ((net_income as f64) - (preferred_dividend as f64)) / (average_shares as f64)
}
