/// Recursively encode octal digits as a decimal integer.
fn encode_octal_digits(value: i64) -> i64 {
    if value == 0 { return 0; }
    encode_octal_digits(value / 8) * 10 + value % 8
}

#[no_mangle]
pub extern "C" fn decimal_to_octal_recursion(value: i64) -> i64 {
    if !(0..=295_600_127).contains(&value) { return -1; }
    encode_octal_digits(value)
}
