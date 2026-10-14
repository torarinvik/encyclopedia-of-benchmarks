/// Convert a most-significant-first octal digit array to radix 16 text.
#[no_mangle]
pub unsafe extern "C" fn octal_to_hexadecimal(digits: *const i64, length: usize,
                                    output: *mut u8, output_capacity: usize) -> i64 {
    if length == 0 || length > 21 { return -1; }
    let mut value = 0i64;
    for index in 0..length {
        let octal_digit = *digits.add(index);
        if !(0..=7).contains(&octal_digit) { return -1; }
        value = value * 8 + octal_digit;
    }
    let mut width = 1usize;
    let mut remaining = value;
    while remaining >= 16 {
        remaining /= 16;
        width += 1;
    }
    if output.is_null() || output_capacity < width { return -2; }
    let mut position = width;
    remaining = value;
    while position > 0 {
        position -= 1;
        let digit = remaining % 16;
        let byte = if digit < 10 { b'0' + digit as u8 } else { b'a' + (digit - 10) as u8 };
        *output.add(position) = byte;
        remaining /= 16;
    }
    width as i64
}
