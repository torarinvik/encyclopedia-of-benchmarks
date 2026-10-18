const MAX_ROWS: usize = 4;
const MAX_INPUT_LENGTH: usize = 7;
const SINGULAR_VALUE_CUTOFF: f64 = 1e-4;

fn integer_in_range(value: f64, minimum: i32, maximum: i32) -> bool {
    value.is_finite() && value >= minimum as f64 && value <= maximum as f64 && value.fract() == 0.0
}

#[no_mangle]
pub unsafe extern "C" fn pseudo_inverse(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    if !integer_in_range(values[0], 1, MAX_ROWS as i32) || !integer_in_range(values[1], 1, 1) {
        return -1;
    }
    let row_count = values[0] as usize;
    let column_count = values[1] as usize;
    if input_length != 2 + row_count * column_count || input_length > 2 + MAX_ROWS {
        return -1;
    }

    let mut column = [0.0_f64; MAX_ROWS];
    let mut squared_norm = 0.0;
    for row in 0..row_count {
        let value = values[2 + row];
        if !(-4.0..=4.0).contains(&value) || value.fract() != 0.0 {
            return -1;
        }
        column[row] = value;
        squared_norm += value * value;
    }
    let singular_value = squared_norm.sqrt();
    let mut staged = [0.0_f64; MAX_ROWS + 2];
    staged[0] = 1.0;
    staged[1] = row_count as f64;
    for row in 0..row_count {
        staged[2 + row] = if singular_value.abs() < SINGULAR_VALUE_CUTOFF {
            0.0
        } else {
            column[row] / squared_norm
        };
    }

    let result_length = 2 + row_count;
    if output.is_null() || output_capacity < result_length {
        return -2;
    }
    for index in 0..result_length {
        unsafe { *output.add(index) = staged[index]; }
    }
    result_length as i64
}
