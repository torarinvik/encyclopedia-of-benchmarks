const MAX_LENGTH: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn autocorrelation(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 4 || length > MAX_LENGTH + 2 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    let lag_value = values[1];
    if count_value < 2 || count_value > MAX_LENGTH as i64 || length != count_value as usize + 2 ||
        lag_value < 0 || lag_value >= count_value { return INVALID_RESULT; }
    let count = count_value as usize;
    let lag = lag_value as usize;
    let data = &values[2..];
    if data.iter().any(|&value| !(-1000..=1000).contains(&value)) { return INVALID_RESULT; }
    let mean = data.iter().map(|&value| value as f64).sum::<f64>() / count as f64;
    let variance_sum = data.iter().map(|&value| {
        let difference = value as f64 - mean;
        difference * difference
    }).sum::<f64>();
    if variance_sum == 0.0 { return INVALID_RESULT; }
    let variance = variance_sum / count as f64;
    let covariance_sum = (lag..count).map(|index| {
        (data[index] as f64 - mean) * (data[index - lag] as f64 - mean)
    }).sum::<f64>();
    (covariance_sum / count as f64) / variance
}
