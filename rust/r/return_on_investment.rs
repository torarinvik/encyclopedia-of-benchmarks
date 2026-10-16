/// Cross-platform scalar implementation of return_on_investment.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn return_on_investment(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let gain = *values.add(0);
    let cost = *values.add(1);
    if gain < -1000000 || gain > 1000000 || cost < 1 || cost > 1000000 { return INVALID_RESULT; }
    ((gain as f64) - (cost as f64)) / (cost as f64)
}
