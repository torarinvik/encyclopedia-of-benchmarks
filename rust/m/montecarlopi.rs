const MAX_PARSEABLE_INPUT_LENGTH: usize = 130;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

fn allowed_coordinate(value: f64) -> bool {
    value == 0.0 || value == 0.25 || value == 0.5 || value == 0.75
}

#[no_mangle]
pub unsafe extern "C" fn montecarlopi(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let point_count = match exact_integer(values[0], 1, 64) { Some(value) => value as usize, None => return -1 };
    if input_length != 1 + 2 * point_count { return -1; }
    let mut inside = 0_usize;
    for point in 0..point_count {
        let x = values[1 + 2 * point];
        let y = values[2 + 2 * point];
        if !allowed_coordinate(x) || !allowed_coordinate(y) { return -1; }
        if x * x + y * y <= 1.0 { inside += 1; }
    }
    let estimate = inside as f64 / point_count as f64 * 4.0;
    if !estimate.is_finite() { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }
    *output = estimate;
    1
}
