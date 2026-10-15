const MAX_N: i64 = 64;
const MAX_ABS_VALUE: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn weighted_average(packed: *const i64, length: usize) -> f64 {
    if packed.is_null() || length < 1 || length > 129 {
        return INVALID_RESULT;
    }
    let packed = std::slice::from_raw_parts(packed, length);
    let n = packed[0];
    if !(1..=MAX_N).contains(&n) || length != (1 + 2 * n) as usize {
        return INVALID_RESULT;
    }
    let mut weighted_sum = 0i64;
    let mut total_weight = 0i64;
    for index in 0..n as usize {
        let value = packed[1 + index];
        let weight = packed[1 + n as usize + index];
        if !(-MAX_ABS_VALUE..=MAX_ABS_VALUE).contains(&value)
            || !(-MAX_ABS_VALUE..=MAX_ABS_VALUE).contains(&weight)
        {
            return INVALID_RESULT;
        }
        weighted_sum += value * weight;
        total_weight += weight;
    }
    if total_weight == 0 {
        return INVALID_RESULT;
    }
    weighted_sum as f64 / total_weight as f64
}
