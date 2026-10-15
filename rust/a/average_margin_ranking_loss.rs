const MAX_LENGTH: usize = 256;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn average_margin_ranking_loss(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 5 || length > 2 * MAX_LENGTH + 3 { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    let margin_value = values[1];
    let label_value = values[2];
    if count_value < 1 || count_value > MAX_LENGTH as i64 || length != 2 * count_value as usize + 3 ||
        !(0..=1000).contains(&margin_value) || (label_value != 1 && label_value != -1) { return INVALID_RESULT; }
    let count = count_value as usize;
    let first_values = &values[3..3 + count];
    let second_values = &values[3 + count..];
    if first_values.iter().chain(second_values).any(|&value| !(-1000..=1000).contains(&value)) {
        return INVALID_RESULT;
    }
    let margin = margin_value as f64;
    let label = label_value as f64;
    let total: f64 = first_values.iter().zip(second_values.iter()).map(|(&first, &second)| {
        (margin - label * (first as f64 - second as f64)).max(0.0)
    }).sum();
    total / count as f64
}
