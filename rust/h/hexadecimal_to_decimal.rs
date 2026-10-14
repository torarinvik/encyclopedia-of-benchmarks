/// Convert most-significant-first hexadecimal digits to a signed 64-bit value.
#[no_mangle]
pub unsafe extern "C" fn hexadecimal_to_decimal(digits: *const i64, length: usize) -> i64 {
    if length == 0 || length > 16 { return -1; }
    if length == 16 && *digits > 7 { return -1; }
    let mut result = 0i64;
    for index in 0..length {
        let digit = *digits.add(index);
        if !(0..=15).contains(&digit) { return -1; }
        result = result * 16 + digit;
    }
    result
}
