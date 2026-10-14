/// Convert a signed 64-bit integer to canonical negabinary digits.
#[no_mangle]
pub unsafe extern "C" fn base_neg2_conversion(input: *const i64, length: usize,
                                                 output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let original = *input;
    let mut width = 0usize;
    let mut remaining = original;
    loop {
        let mut quotient = remaining / -2;
        let mut digit = remaining % -2;
        if digit < 0 { digit += 2; quotient += 1; }
        remaining = quotient;
        width += 1;
        if remaining == 0 { break; }
    }
    if output.is_null() || output_capacity < width { return -2; }
    let mut top = 0usize;
    remaining = original;
    loop {
        let mut quotient = remaining / -2;
        let mut digit = remaining % -2;
        if digit < 0 { digit += 2; quotient += 1; }
        *output.add(top) = b'0' + digit as u8;
        top += 1;
        remaining = quotient;
        if remaining == 0 { break; }
    }
    let mut left = 0usize;
    let mut right = top - 1;
    while left < right {
        let temporary = *output.add(left);
        *output.add(left) = *output.add(right);
        *output.add(right) = temporary;
        left += 1; right -= 1;
    }
    top as i64
}
