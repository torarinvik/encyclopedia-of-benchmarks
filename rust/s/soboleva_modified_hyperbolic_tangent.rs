const MAX_SAMPLE_COUNT: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 38;

#[no_mangle]
pub unsafe extern "C" fn soboleva_modified_hyperbolic_tangent(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let count_value = values[0];
    if !count_value.is_finite() || count_value.fract() != 0.0 || count_value < 1.0 || count_value > MAX_SAMPLE_COUNT as f64 { return -1; }
    let count = count_value as usize;
    if input_length != 5 + count { return -1; }

    let a = values[1];
    let b = values[2];
    let c = values[3];
    let d = values[4];
    for coefficient in [a, b, c, d] {
        if !coefficient.is_finite() || !(-2.0..=2.0).contains(&coefficient) { return -1; }
    }
    for &sample in &values[5..] {
        if !sample.is_finite() || !(-20.0..=20.0).contains(&sample) { return -1; }
    }
    if output.is_null() || output_capacity < count { return -2; }

    for (index, &sample) in values[5..].iter().enumerate() {
        let exp_ax = (a * sample).exp();
        let exp_neg_bx = (-b * sample).exp();
        let numerator = exp_ax - exp_neg_bx;
        let exp_cx = (c * sample).exp();
        let exp_neg_dx = (-d * sample).exp();
        let denominator = exp_cx + exp_neg_dx;
        *output.add(index) = numerator / denominator;
    }
    count as i64
}
