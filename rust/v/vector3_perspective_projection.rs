const INPUT_LIMIT: f64 = 1_000_000.0;
const DENOMINATOR_FLOOR: f64 = 0.000001;
const OUTPUT_LIMIT: f64 = 1.0e25;

#[no_mangle]
pub unsafe extern "C" fn vector3_perspective_projection(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_len != 5 { return -1; }
    let values = std::slice::from_raw_parts(input, input_len);
    if values.iter().any(|value| !value.is_finite() || value.abs() > INPUT_LIMIT) { return -1; }
    let denominator = values[2] + values[4];
    if denominator.abs() < DENOMINATOR_FLOOR { return -1; }
    let x = ((values[0] * values[4]) / denominator) * values[3];
    let y = ((values[1] * values[4]) / denominator) * values[3];
    if !x.is_finite() || !y.is_finite() || x.abs() > OUTPUT_LIMIT || y.abs() > OUTPUT_LIMIT { return -1; }
    if output.is_null() || output_capacity < 2 { return -2; }
    *output = x;
    *output.add(1) = y;
    2
}
