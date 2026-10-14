/// Convert a most-significant-first hexadecimal digit array to radix 8 text.
#[no_mangle]
pub unsafe extern "C" fn hexadecimal_to_octal(digits: *const i64, length: usize,
                                    output: *mut u8, output_capacity: usize) -> i64 {
    if length == 0 || length > 16 { return -1; }
    if length == 16 && *digits > 7 { return -1; }
    let mut value = 0i64;
    for index in 0..length {
        let hex_digit = *digits.add(index);
        if !(0..=15).contains(&hex_digit) { return -1; }
        value = value * 16 + hex_digit;
    }
    let mut width = 1usize;
    let mut remaining = value;
    while remaining >= 8 {
        remaining /= 8;
        width += 1;
    }
    if output.is_null() || output_capacity < width { return -2; }
    let mut position = width;
    remaining = value;
    while position > 0 {
        position -= 1;
        let digit = remaining % 8;
        let byte = if digit < 10 { b'0' + digit as u8 } else { b'a' + (digit - 10) as u8 };
        *output.add(position) = byte;
        remaining /= 8;
    }
    width as i64
}
