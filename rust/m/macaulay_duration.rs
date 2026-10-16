const SCALE: i64 = 1_000_000;
const MAX_FACE_VALUE_MICRO: i64 = 1_000_000_000_000;
const MAX_RATE_MICRO: i64 = 1_000_000;
const MAX_PERIODS: i64 = 64;
const MAX_INPUT_LENGTH: usize = 5;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn macaulay_duration(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 4 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let face_micro = *values;
    let coupon_micro = *values.add(1);
    let periods = *values.add(2);
    let yield_micro = *values.add(3);
    if face_micro < 1 || face_micro > MAX_FACE_VALUE_MICRO || coupon_micro < 0 || coupon_micro > MAX_RATE_MICRO
            || periods < 1 || periods > MAX_PERIODS || yield_micro < 1 || yield_micro > MAX_RATE_MICRO {
        return INVALID_RESULT;
    }
    let face_value = face_micro as f64 / SCALE as f64;
    let coupon_rate = coupon_micro as f64 / SCALE as f64;
    let yield_rate = yield_micro as f64 / SCALE as f64;
    let mut total_present_value = 0.0;
    let mut total_time_weighted_value = 0.0;
    for period in 1..=periods {
        let cash_flow = face_value * coupon_rate + if period == periods { face_value } else { 0.0 };
        let time_weighted_value = (period as f64 * cash_flow) / (1.0 + yield_rate).powf(period as f64);
        total_time_weighted_value += time_weighted_value;
        let present_value = cash_flow / (1.0 + yield_rate).powf(period as f64);
        total_present_value += present_value;
    }
    total_time_weighted_value / total_present_value
}
