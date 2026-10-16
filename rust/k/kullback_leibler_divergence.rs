const MAX_COUNT: i64 = 64;
const MAX_INPUT_LENGTH: usize = 129;
const SCALE: f64 = 1_000_000.0;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn kullback_leibler_divergence(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let count_value = input[0];
    if !(1..=MAX_COUNT).contains(&count_value) || length != 1 + 2 * count_value as usize {
        return INVALID_RESULT;
    }
    let count = count_value as usize;

    for i in 0..count {
        let target = input[1 + i];
        let prediction = input[1 + count + i];
        if !(0..=1_000_000).contains(&target)
            || !(0..=1_000_000).contains(&prediction)
            || (target > 0 && prediction == 0)
        {
            return INVALID_RESULT;
        }
    }
    let mut total = 0.0;
    for i in 0..count {
        let target_scaled = input[1 + i];
        if target_scaled == 0 {
            continue;
        }
        let prediction_scaled = input[1 + count + i];
        let target = target_scaled as f64 / SCALE;
        let prediction = prediction_scaled as f64 / SCALE;
        total += target * (target / prediction).ln();
    }
    total
}
