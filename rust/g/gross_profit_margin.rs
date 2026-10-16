/// Cross-platform scalar implementation of gross_profit_margin.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn gross_profit_margin(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let revenue = *values.add(0);
    let cost = *values.add(1);
    if revenue < 1 || revenue > 1000000 || cost < 0 || cost > 1000000 { return INVALID_RESULT; }
    ((revenue as f64) - (cost as f64)) / (revenue as f64)
}
