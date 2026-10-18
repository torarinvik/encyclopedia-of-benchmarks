const MIN_RETURNS: usize = 2;
const MAX_RETURNS: usize = 60;
const MAX_INPUT_LENGTH: usize = 62;
const MAX_OUTPUT_LENGTH: usize = 63;
const Z_95: f64 = 1.6448536269514722;

#[no_mangle]
pub unsafe extern "C" fn update_returns(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 + MIN_RETURNS || input_length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    if values[0] < MIN_RETURNS as f64 || values[0] > MAX_RETURNS as f64 || values[0].fract() != 0.0 {
        return -1;
    }
    let count = values[0] as usize;
    if input_length != count + 1 {
        return -1;
    }

    let mut returns = [0.0; MAX_RETURNS];
    let mut sum = 0.0;
    for i in 0..count {
        let value = values[i + 1];
        if !(-0.25..=0.25).contains(&value) {
            return -1;
        }
        returns[i] = value;
        sum += value;
    }
    let mean = sum / count as f64;
    let mut squared_deviation_sum = 0.0;
    for i in 0..count {
        let deviation = returns[i] - mean;
        squared_deviation_sum += deviation * deviation;
    }
    let volatility = (squared_deviation_sum / (count - 1) as f64).sqrt();
    if !mean.is_finite() || !volatility.is_finite() || volatility == 0.0 {
        return -1;
    }
    let var = 100000.0 * (Z_95 * volatility - mean);
    if !var.is_finite() {
        return -1;
    }

    let mut staged = [0.0; MAX_OUTPUT_LENGTH];
    for i in 0..count {
        staged[i] = returns[i];
    }
    staged[count] = mean;
    staged[count + 1] = volatility;
    staged[count + 2] = var;
    let result_length = count + 3;
    if output.is_null() || output_capacity < result_length {
        return -2;
    }
    for i in 0..result_length {
        unsafe { *output.add(i) = staged[i]; }
    }
    result_length as i64
}
