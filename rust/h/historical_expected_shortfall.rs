const INVALID_RESULT: i64 = -1;
const OUTPUT_ERROR: i64 = -2;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 69;

#[no_mangle]
pub unsafe extern "C" fn historical_expected_shortfall(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 24 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if values.iter().any(|value| !value.is_finite()) { return INVALID_RESULT; }
    let portfolio_value = values[0];
    let confidence_level = values[1];
    let time_horizon = values[2];
    let count_value = values[3];
    if !(20.0..=64.0).contains(&count_value) || count_value.fract() != 0.0 { return INVALID_RESULT; }
    let return_count = count_value as usize;
    if input_length != 4 + return_count || !(100.0..=1_000_000.0).contains(&portfolio_value) ||
        !(0.5..=0.95).contains(&confidence_level) || !(1.0..=10.0).contains(&time_horizon) {
        return INVALID_RESULT;
    }
    let mut sorted_returns = [0.0_f64; 64];
    for i in 0..return_count {
        let value = values[4 + i];
        if !(-0.25..=0.25).contains(&value) { return INVALID_RESULT; }
        sorted_returns[i] = value;
    }
    let index = ((1.0 - confidence_level) * return_count as f64).floor() as usize;
    if index < 1 { return INVALID_RESULT; }
    sorted_returns[..return_count].sort_by(|a, b| a.total_cmp(b));
    let mut tail_sum = 0.0;
    for value in &sorted_returns[..index] { tail_sum += value; }
    let result = (-(tail_sum / index as f64) * portfolio_value) * time_horizon.sqrt();
    if output.is_null() || output_capacity < 1 { return OUTPUT_ERROR; }
    output.write(result);
    1
}
