/// ASCII alphanumeric palindrome check, ignoring case and punctuation.
fn folded_alphanumeric(value: u64) -> bool {
    value.wrapping_sub(48) <= 9 || value.wrapping_sub(97) <= 25
}

#[no_mangle]
pub extern "C" fn valid_palindrome(text: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    if length == 0 { return 1; }
    if text.is_null() { return -1; }
    let values = unsafe { std::slice::from_raw_parts(text, length) };
    if length == 1 { return if values[0] as u64 <= 127 { 1 } else { -1 }; }

    let (mut left, mut right) = (0, length);
    while left < right {
        let first = values[left] as u64 | 32;
        if first > 127 { return -1; }
        left += 1;
        if !folded_alphanumeric(first) { continue; }
        while left < right {
            right -= 1;
            let last = values[right] as u64 | 32;
            if last > 127 { return -1; }
            if folded_alphanumeric(last) {
                if first != last {
                    let bits = values[left..right].iter().fold(0, |bits, &value| bits | value as u64);
                    return if bits > 127 { -1 } else { 0 };
                }
                break;
            }
        }
    }
    1
}
