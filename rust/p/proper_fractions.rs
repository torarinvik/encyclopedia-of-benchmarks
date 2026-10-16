/// Emit reduced proper fractions for one positive denominator.
fn gcd(mut left: u64, mut right: u64) -> u64 {
    while right != 0 { let remainder = left % right; left = right; right = remainder; }
    left
}

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
pub unsafe extern "C" fn proper_fractions(values: *const i64, length: usize,
                                             output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let denominator = *values;
    if !(0..=256).contains(&denominator) { return -1; }
    if denominator <= 1 { return 0; }
    let denominator = denominator as u64;
    let mut needed = 0usize;
    for numerator in 1..denominator {
        if gcd(numerator, denominator) == 1 {
            needed += decimal_width(numerator) + decimal_width(denominator) + 2;
        }
    }
    if output.is_null() || output_capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, output_capacity);
    let mut position = 0;
    for numerator in 1..denominator {
        if gcd(numerator, denominator) != 1 { continue; }
        position = append_decimal(out, position, numerator);
        out[position] = b'/'; position += 1;
        position = append_decimal(out, position, denominator);
        out[position] = b'\n'; position += 1;
    }
    position as i64
}
