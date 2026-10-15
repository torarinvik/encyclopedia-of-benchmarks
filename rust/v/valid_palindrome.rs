fn is_ascii_alphanumeric(value: i64) -> bool {
    (48..=57).contains(&value) || (65..=90).contains(&value) || (97..=122).contains(&value)
}

fn ascii_lower(value: i64) -> i64 {
    if (65..=90).contains(&value) { value + 32 } else { value }
}

/// ASCII alphanumeric palindrome check, ignoring case and punctuation.
#[no_mangle]
pub extern "C" fn valid_palindrome(text: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    if length == 0 { return 1; }
    let text = unsafe { std::slice::from_raw_parts(text, length) };
    if text.iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    let mut left = 0usize;
    let mut right = length;
    while left < right {
        while left < right && !is_ascii_alphanumeric(text[left]) { left += 1; }
        while left < right && !is_ascii_alphanumeric(text[right - 1]) { right -= 1; }
        if left < right && ascii_lower(text[left]) != ascii_lower(text[right - 1]) { return 0; }
        if left < right { left += 1; right -= 1; }
    }
    1
}
