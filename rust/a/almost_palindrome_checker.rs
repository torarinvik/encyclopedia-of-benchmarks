const MAX_LENGTH: usize = 100_000;

fn is_palindrome_range(text: &[i64], mut left: usize, mut right: usize) -> bool {
    while left < right {
        if text[left] != text[right - 1] { return false; }
        left += 1;
        right -= 1;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn almost_palindrome_checker(text: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH { return -1; }
    if length == 0 { return 1; }
    let text = std::slice::from_raw_parts(text, length);
    if text.iter().any(|&value| !(97..=122).contains(&value)) { return -1; }
    let mut left = 0usize;
    let mut right = length;
    while left < right {
        if text[left] != text[right - 1] {
            return if is_palindrome_range(text, left + 1, right) ||
                is_palindrome_range(text, left, right - 1) { 1 } else { 0 };
        }
        left += 1;
        right -= 1;
    }
    1
}
