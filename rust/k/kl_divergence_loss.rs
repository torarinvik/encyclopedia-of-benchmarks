const MAX_COUNT: i64 = 64;
const MAX_INPUT_LENGTH: usize = 130;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn kl_divergence_loss(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let actual_count_value = values[0];
    let predicted_count_value = values[1];
    if !(0..=MAX_COUNT).contains(&actual_count_value) || !(0..=MAX_COUNT).contains(&predicted_count_value) {
        return INVALID_RESULT;
    }
    let actual_count = actual_count_value as usize;
    let predicted_count = predicted_count_value as usize;
    if length != 2 + actual_count + predicted_count { return INVALID_RESULT; }
    if values[2..2 + actual_count].iter().any(|&value| !(0..=1_000_000).contains(&value)) ||
        values[2 + actual_count..].iter().any(|&value| !(0..=1_000_000).contains(&value)) {
        return INVALID_RESULT;
    }

    let paired_count = actual_count.min(predicted_count);
    let mut total = 0.0;
    for index in 0..paired_count {
        let actual = values[2 + index] as f64 / 1_000_000.0 + 1e-5;
        let predicted = values[2 + actual_count + index] as f64 / 1_000_000.0 + 1e-5;
        total += actual * (actual / predicted).ln();
    }
    total
}
