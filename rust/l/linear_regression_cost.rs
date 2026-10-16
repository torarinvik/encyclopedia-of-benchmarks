const MAX_OBSERVATIONS: usize = 64;
const MAX_FEATURES: usize = 16;
const MAX_INPUT_LENGTH: usize = 2 + MAX_OBSERVATIONS * MAX_FEATURES + MAX_FEATURES + MAX_OBSERVATIONS;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn linear_regression_cost(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=MAX_OBSERVATIONS as i64).contains(&values[0]) ||
       !(1..=MAX_FEATURES as i64).contains(&values[1]) { return INVALID_RESULT; }
    let observations = values[0] as usize;
    let features = values[1] as usize;
    let matrix_length = observations * features;
    if length != 2 + matrix_length + features + observations { return INVALID_RESULT; }
    if values[2..].iter().any(|value| !(-1000..=1000).contains(value)) { return INVALID_RESULT; }

    let weights_start = 2 + matrix_length;
    let targets_start = weights_start + features;
    let mut squared_error_sum = 0.0;
    for row in 0..observations {
        let mut prediction = 0.0;
        let row_start = 2 + row * features;
        for column in 0..features {
            prediction += values[row_start + column] as f64 * values[weights_start + column] as f64;
        }
        let error = prediction - values[targets_start + row] as f64;
        squared_error_sum += error * error;
    }
    squared_error_sum / (2.0 * observations as f64)
}
