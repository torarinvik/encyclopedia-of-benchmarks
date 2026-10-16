const MAX_RATE_MICRO: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn exponential_dist(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let operation = *values;
    let rate_micro = *values.add(1);
    if operation < 0 || operation > 2 || rate_micro <= 0 || rate_micro > MAX_RATE_MICRO {
        return INVALID_RESULT;
    }
    let rate = rate_micro as f64 / 1_000_000.0;
    if operation == 1 { return 1.0 / rate.powf(2.0); }
    1.0 / rate
}
