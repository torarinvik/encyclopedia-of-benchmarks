/// Check whether an ASCII string is a palindrome ignoring ASCII letter case.
fn ascii_lower(value: i64) -> i64 {
    if (65..=90).contains(&value) { value + 32 } else { value }
}

#[no_mangle]
pub unsafe extern "C" fn case_insensitive_palindrome(values: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    for index in 0..length {
        let value = *values.add(index);
        if value < 0 || value > 127 { return -1; }
    }
    for left in 0..length / 2 {
        if ascii_lower(*values.add(left)) != ascii_lower(*values.add(length - 1 - left)) { return 0; }
    }
    1
}
