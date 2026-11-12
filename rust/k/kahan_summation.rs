#[no_mangle]
pub unsafe extern "C" fn kahan_summation(values: *const f64, length: usize,
                                           output: *mut f64, capacity: usize) -> i64 {
    if values.is_null() || length > 256 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input.iter().any(|value| !value.is_finite() || value.abs() > 1.0e100) {
        return -1;
    }
    if output.is_null() || capacity < 1 { return -2; }

    let mut sum = 0.0_f64;
    let mut correction = 0.0_f64;
    for &value in input {
        let adjusted = value - correction;
        let next = sum + adjusted;
        correction = (next - sum) - adjusted;
        sum = next;
    }
    *output = sum;
    1
}
