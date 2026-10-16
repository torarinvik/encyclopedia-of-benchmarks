/// Cross-platform scalar implementation of debt_to_equity.
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn debt_to_equity(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let debt = *values.add(0);
    let equity = *values.add(1);
    if debt < 0 || debt > 1000000 || equity < 1 || equity > 1000000 { return INVALID_RESULT; }
    (debt as f64) / (equity as f64)
}
