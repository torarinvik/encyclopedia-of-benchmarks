const MAX_OUTPUT_BYTES: usize = 41;

#[no_mangle]
pub unsafe extern "C" fn balanced_ternary_conversion(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let value = *input;
    let mut reversed = [0_u8; MAX_OUTPUT_BYTES];
    let mut digit_count = 0_usize;
    if value == 0 {
        reversed[digit_count] = b'0';
        digit_count += 1;
    }
    let mut remaining = value;
    while remaining != 0 {
        let mut quotient = remaining / 3;
        let remainder = remaining % 3;
        let digit = if remainder == 2 {
            quotient += 1;
            b'Z'
        } else if remainder == -2 {
            quotient -= 1;
            b'1'
        } else if remainder == -1 {
            b'Z'
        } else if remainder == 0 {
            b'0'
        } else {
            b'1'
        };
        reversed[digit_count] = digit;
        digit_count += 1;
        remaining = quotient;
    }
    if output.is_null() || capacity < digit_count { return -2; }
    for index in 0..digit_count {
        *output.add(index) = reversed[digit_count - index - 1];
    }
    digit_count as i64
}
