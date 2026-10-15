/// Convert a nonnegative reflected Gray-code integer to its binary integer.
#[no_mangle]
pub extern "C" fn gray_to_binary(gray: i64) -> i64 {
    if gray < 0 { return -1; }
    let mut binary = gray;
    let mut remaining = gray >> 1;
    while remaining != 0 {
        binary ^= remaining;
        remaining >>= 1;
    }
    binary
}
