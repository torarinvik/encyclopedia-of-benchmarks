fn gcd_positive(mut left: i64, mut right: i64) -> i64 {
    while right != 0 { let remainder = left % right; left = right; right = remainder; }
    left
}

#[no_mangle]
pub extern "C" fn continued_fraction(input: *const i64, length: usize,
                                      output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (mut numerator, mut denominator) = (values[0], values[1]);
    if numerator < -1_000_000 || numerator > 1_000_000 || denominator < -1_000_000 ||
        denominator > 1_000_000 || denominator == 0 { return -1; }
    let divisor = gcd_positive(numerator.abs(), denominator.abs());
    numerator /= divisor;
    denominator /= divisor;
    if denominator < 0 { numerator = -numerator; denominator = -denominator; }
    let mut coefficients = [0i64; 32];
    let mut count = 0usize;
    loop {
        let mut quotient = numerator / denominator;
        let mut remainder = numerator % denominator;
        if remainder < 0 { quotient -= 1; remainder += denominator; }
        if count == coefficients.len() { return -1; }
        coefficients[count] = quotient;
        count += 1;
        if remainder == 0 { break; }
        numerator = denominator;
        denominator = remainder;
    }
    let bytes = count * 8;
    if bytes > capacity || output.is_null() { return -2; }
    for (index, coefficient) in coefficients[..count].iter().enumerate() {
        let encoded = coefficient.to_le_bytes();
        unsafe { std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(index * 8), 8); }
    }
    bytes as i64
}
