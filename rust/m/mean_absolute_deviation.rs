const MAX_LENGTH: usize = 256;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn mean_absolute_deviation(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > MAX_LENGTH + 1 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    if count_value < 1 || count_value > MAX_LENGTH as i64 || length != count_value as usize + 1 {
        return INVALID_RESULT;
    }
    let data = &values[1..];
    if data.iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return INVALID_RESULT; }
    let count = data.len() as f64;
    let sum: f64 = data.iter().map(|&value| value as f64).sum();
    let mean = sum / count;
    let absolute_sum: f64 = data.iter().map(|&value| (value as f64 - mean).abs()).sum();
    absolute_sum / count
}
