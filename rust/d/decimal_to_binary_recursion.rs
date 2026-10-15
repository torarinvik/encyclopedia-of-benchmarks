/// Recursively encode binary digits as a decimal integer, for inputs 0..1023.
fn encode_binary_digits(value: i64) -> i64 {
    if value == 0 { return 0; }
    (value % 2) + 10 * encode_binary_digits(value / 2)
}

#[no_mangle]
pub extern "C" fn decimal_to_binary_recursion(value: i64) -> i64 {
    if !(0..=1023).contains(&value) { return -1; }
    encode_binary_digits(value)
}
