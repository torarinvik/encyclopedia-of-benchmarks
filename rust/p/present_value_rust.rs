const MAX_CASH_FLOWS: i64 = 8;
const MAX_RATE_PPM: i64 = 1_000_000;
const MAX_CASH_FLOW_MILLI: i64 = 1_000_000;
const MAX_INPUT_LENGTH: usize = 11;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn present_value_rust(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let count = *values;
    let rate_ppm = *values.add(1);
    if count < 1 || count > MAX_CASH_FLOWS || length != count as usize + 2 ||
        (rate_ppm != 0 && rate_ppm != MAX_RATE_PPM) {
        return INVALID_RESULT;
    }

    let discount_rate = rate_ppm as f64 / 1_000_000.0;
    let mut present_value = 0.0;
    for index in 0..count as usize {
        let cash_flow_milli = *values.add(index + 2);
        if cash_flow_milli < -MAX_CASH_FLOW_MILLI || cash_flow_milli > MAX_CASH_FLOW_MILLI || cash_flow_milli % 125 != 0 {
            return INVALID_RESULT;
        }
        let cash_flow = cash_flow_milli as f64 / 1_000.0;
        present_value += cash_flow / (1.0 + discount_rate).powi(index as i32);
    }
    (present_value * 100.0).round() / 100.0
}
