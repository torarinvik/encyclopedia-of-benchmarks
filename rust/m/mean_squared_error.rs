const MAX_COUNT: i64 = 256;
const MAX_PARSED_COUNT: i64 = 257;
const MAX_SAMPLE: i64 = 1_000_000;
const MAX_INPUT_LENGTH: usize = 515;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn mean_squared_error(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let count_value = *values;
    if count_value < 0 || count_value > MAX_PARSED_COUNT { return INVALID_RESULT; }
    if length != (1 + 2 * count_value) as usize || count_value == 0 || count_value > MAX_COUNT {
        return INVALID_RESULT;
    }
    let count = count_value as usize;
    for index in 0..count * 2 {
        let sample = *values.add(1 + index);
        if sample < -MAX_SAMPLE || sample > MAX_SAMPLE { return INVALID_RESULT; }
    }
    let mut total = 0.0;
    for index in 0..count {
        let true_value = *values.add(1 + index) as f64 / 1_000_000.0;
        let predicted_value = *values.add(1 + count + index) as f64 / 1_000_000.0;
        let difference = true_value - predicted_value;
        total += difference * difference;
    }
    total / count as f64
}
