/// Emit the bounded Python P-series list as newline-delimited ASCII.
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

#[no_mangle]
pub unsafe extern "C" fn p_series(values: *const i64, length: usize,
                                    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let nth_term = *values;
    let power = *values.add(1);
    if !(-256..=256).contains(&nth_term) || !(0..=7).contains(&power) { return -1; }
    if nth_term <= 0 { return 0; }

    let mut needed = 2usize;
    for term in 2..=nth_term as u64 {
        let mut denominator = 1u64;
        for _ in 0..power { denominator *= term; }
        needed += 5 + decimal_width(denominator);
    }
    if output.is_null() || output_capacity < needed { return -2; }

    let out = std::slice::from_raw_parts_mut(output, output_capacity);
    let mut position = 0;
    out[position] = b'1'; position += 1;
    out[position] = b'\n'; position += 1;
    for term in 2..=nth_term as u64 {
        let mut denominator = 1u64;
        for _ in 0..power { denominator *= term; }
        out[position] = b'1'; position += 1;
        out[position] = b' '; position += 1;
        out[position] = b'/'; position += 1;
        out[position] = b' '; position += 1;
        position = append_decimal(out, position, denominator);
        out[position] = b'\n'; position += 1;
    }
    position as i64
}
