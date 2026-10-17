#[no_mangle]
pub unsafe extern "C" fn piecewise_without_inbuilt(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_len != 1 {
        return -1;
    }
    let x = *input;
    if !x.is_finite() || !(-10.0..=10.0).contains(&x) {
        return -1;
    }

    let y = if x <= -0.5 { 0.0 } else if x < 0.5 { x } else { 1.0 };
    if output.is_null() || output_capacity < 1 {
        return -2;
    }
    *output = y;
    1
}
