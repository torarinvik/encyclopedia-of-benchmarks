/// Check whether an exact ASCII string is a palindrome.
#[no_mangle]
pub unsafe extern "C" fn palindrome(values: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    for index in 0..length {
        let value = *values.add(index);
        if value < 0 || value > 127 { return -1; }
    }
    for left in 0..length / 2 {
        if *values.add(left) != *values.add(length - 1 - left) { return 0; }
    }
    1
}
