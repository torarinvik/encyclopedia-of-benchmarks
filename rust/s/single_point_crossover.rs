const MAX_PARENT_LENGTH: usize = 31;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_PARENT_LENGTH;

#[no_mangle]
pub unsafe extern "C" fn single_point_crossover(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 6 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let n_value = values[0];
    let cut_value = values[1];
    if !n_value.is_finite() || n_value < 2.0 || n_value > MAX_PARENT_LENGTH as f64 || n_value.fract() != 0.0 ||
        !cut_value.is_finite() || cut_value < 1.0 || cut_value > n_value - 1.0 || cut_value.fract() != 0.0 { return -1; }
    let n = n_value as usize;
    let cut = cut_value as usize;
    if input_length != 2 + 2 * n { return -1; }
    let mut first = [0.0_f64; MAX_PARENT_LENGTH];
    let mut second = [0.0_f64; MAX_PARENT_LENGTH];
    for index in 0..n {
        first[index] = values[2 + index];
        second[index] = values[2 + n + index];
        if !first[index].is_finite() || !second[index].is_finite() { return -1; }
    }
    let required = 2 * n;
    if output.is_null() || output_capacity < required { return -2; }
    for index in 0..n {
        *output.add(index) = if index < cut { first[index] } else { second[index] };
        *output.add(n + index) = if index < cut { second[index] } else { first[index] };
    }
    required as i64
}
