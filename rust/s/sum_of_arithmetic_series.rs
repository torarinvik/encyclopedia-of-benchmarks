const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn sum_of_arithmetic_series(packed: *const i64, length: usize) -> f64 {
    if packed.is_null() || length != 3 {
        return INVALID_RESULT;
    }
    let packed = std::slice::from_raw_parts(packed, length);
    let a = packed[0];
    let d = packed[1];
    let n = packed[2];
    if a < -1000 || a > 1000 || d < -1000 || d > 1000 || n < 1 || n > 1000 {
        return INVALID_RESULT;
    }
    let result = n * (2 * a + (n - 1) * d) / 2;
    result as f64
}
