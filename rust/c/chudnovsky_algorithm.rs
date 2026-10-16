const MAX_PRECISION: usize = 12;

fn sqrt_10005() -> f64 {
    let mut root = 100.0;
    for _ in 0..8 { root = 0.5 * (root + 10005.0 / root); }
    root
}

#[no_mangle]
pub unsafe extern "C" fn chudnovsky_algorithm(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let precision_value = *values;
    if precision_value < 1 || precision_value > MAX_PRECISION as i64 { return -1; }
    let precision = precision_value as usize;
    let output_length = if precision == 1 { 0 } else { precision };
    if capacity < output_length || (output_length > 0 && output.is_null()) { return -2; }
    if precision == 1 { return 0; }

    let pi = (426880.0 * sqrt_10005()) / 13591409.0;
    let mut fraction = pi - 3.0;
    *output = b'3';
    *output.add(1) = b'.';
    for digit in 0..precision - 2 {
        fraction *= 10.0;
        let next_digit = fraction as u8;
        *output.add(2 + digit) = b'0' + next_digit;
        fraction -= next_digit as f64;
    }
    output_length as i64
}
