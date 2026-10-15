/// Convert a nonnegative integer to its binary-reflected Gray code.
#[no_mangle]
pub extern "C" fn binary_to_gray_code(value: i64) -> i64 {
    if value < 0 { return -1; }
    value ^ (value >> 1)
}
