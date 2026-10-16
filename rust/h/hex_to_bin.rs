const INVALID_RESULT: i64 = i64::MIN;

fn hex_digit(byte: i64) -> i64 {
    if (48..=57).contains(&byte) { return byte - 48; }
    if (65..=70).contains(&byte) { return byte - 65 + 10; }
    if (97..=102).contains(&byte) { return byte - 97 + 10; }
    -1
}

/// Return the decimal integer formed by the binary digits of a bounded hex value.
#[no_mangle]
pub unsafe extern "C" fn hex_to_bin(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 5 { return INVALID_RESULT; }
    let bytes = unsafe { core::slice::from_raw_parts(input, length) };
    let mut start = 0usize;
    let mut sign = 1i64;
    if bytes[0] == 45 {
        sign = -1;
        start = 1;
    }
    let digit_count = length - start;
    if !(1..=4).contains(&digit_count) { return INVALID_RESULT; }

    let mut value = 0i64;
    for byte in &bytes[start..] {
        let digit = hex_digit(*byte);
        if digit < 0 { return INVALID_RESULT; }
        value = value * 16 + digit;
    }
    if value == 0 { return INVALID_RESULT; }

    let mut decimal_binary_digits = 0i64;
    let mut place = 1i64;
    while value > 0 {
        decimal_binary_digits += (value % 2) * place;
        value /= 2;
        if value > 0 { place *= 10; }
    }
    sign * decimal_binary_digits
}
