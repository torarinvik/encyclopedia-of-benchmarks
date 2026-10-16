/// Emit the pinned default logarithmic-series expressions as ASCII lines.
fn decimal_width(mut value: u64) -> usize {
    let mut width = 1;
    while value >= 10 { value /= 10; width += 1; }
    width
}

fn append_decimal(output: &mut [u8], mut position: usize, mut value: u64) -> usize {
    let mut digits = [0u8; 20];
    let mut count = 0;
    loop {
        digits[count] = (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        output[position] = b'0' + digits[count];
        position += 1;
    }
    position
}

fn has_negative_sign(delta: i64, term: i64) -> bool {
    (delta < 0 && term % 2 == 1) || (delta >= 0 && term % 2 == 0)
}

#[no_mangle]
pub unsafe extern "C" fn logarithmic_series(values: *const i64, length: usize,
                                               output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let x_value = *values;
    let n_terms = *values.add(1);
    if !(-10..=10).contains(&x_value) || !(-64..=256).contains(&n_terms) { return -1; }
    if n_terms <= 0 { return 0; }
    let delta = x_value - 1;
    let base = (if delta < 0 { -delta } else { delta }) as u64;
    let mut needed = 0usize;
    for term in 1..=n_terms {
        needed += (if has_negative_sign(delta, term) { 2 } else { 1 })
            + decimal_width(base) + 2 * decimal_width(term as u64) + 4;
    }
    if output.is_null() || output_capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, output_capacity);
    let mut position = 0;
    for term in 1..=n_terms {
        if has_negative_sign(delta, term) { out[position] = b'-'; position += 1; }
        out[position] = b'('; position += 1;
        position = append_decimal(out, position, base);
        out[position] = b'^'; position += 1;
        position = append_decimal(out, position, term as u64);
        out[position] = b')'; position += 1;
        out[position] = b'/'; position += 1;
        position = append_decimal(out, position, term as u64);
        out[position] = b'\n'; position += 1;
    }
    position as i64
}
