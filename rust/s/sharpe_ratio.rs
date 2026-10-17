const MAX_PARSEABLE_LENGTH: usize = 67;
const MAX_SAMPLE_COUNT: i64 = 64;
const SCALE: f64 = 1_000_000.0;
const MIN_RETURN_MICRO: i64 = -200_000;
const MAX_RETURN_MICRO: i64 = 200_000;
const MIN_RISK_FREE_MICRO: i64 = -100_000;
const MAX_RISK_FREE_MICRO: i64 = 100_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn sharpe_ratio(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 || length > MAX_PARSEABLE_LENGTH {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(values, length);
    let count_value = values[0];
    if !(2..=MAX_SAMPLE_COUNT).contains(&count_value)
        || length != count_value as usize + 2 {
        return INVALID_RESULT;
    }
    let count = count_value as usize;
    let risk_free_micro = values[count + 1];
    if !(MIN_RISK_FREE_MICRO..=MAX_RISK_FREE_MICRO).contains(&risk_free_micro) {
        return INVALID_RESULT;
    }

    let mut sum = 0.0f64;
    let mut constant_returns = true;
    for index in 0..count {
        let return_micro = values[index + 1];
        if !(MIN_RETURN_MICRO..=MAX_RETURN_MICRO).contains(&return_micro) {
            return INVALID_RESULT;
        }
        if return_micro != values[1] { constant_returns = false; }
        sum += return_micro as f64 / SCALE;
    }
    if constant_returns { return INVALID_RESULT; }

    let mean = sum / count as f64;
    let risk_free_rate = risk_free_micro as f64 / SCALE;
    let excess_return = mean - risk_free_rate;
    let mut squared_deviations = 0.0f64;
    for index in 0..count {
        let return_value = values[index + 1] as f64 / SCALE;
        let difference = return_value - mean;
        squared_deviations += difference.powf(2.0);
    }
    let variance = squared_deviations / (count - 1) as f64;
    let standard_deviation = variance.sqrt();
    if standard_deviation == 0.0 { return INVALID_RESULT; }
    excess_return / standard_deviation
}
