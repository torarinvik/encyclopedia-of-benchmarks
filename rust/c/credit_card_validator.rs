const MAX_TEXT_LENGTH: usize = 64;

/// Validate an ASCII card string using the source prefix and Luhn rules.
#[no_mangle]
pub extern "C" fn credit_card_validator(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_TEXT_LENGTH + 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n = values[0];
    if n < 0 || n > MAX_TEXT_LENGTH as i64 || length != n as usize + 1 { return -1; }
    let mut all_digits = true;
    for &ch in &values[1..] {
        if !(0..=127).contains(&ch) { return -1; }
        if ch < b'0' as i64 || ch > b'9' as i64 { all_digits = false; }
    }
    if !all_digits || n < 13 || n > 16 { return 0; }
    let first = values[1] - b'0' as i64;
    let second = values[2] - b'0' as i64;
    if !(first == 4 || first == 5 || first == 6 || (first == 3 && (second == 4 || second == 5 || second == 7))) { return 0; }
    let mut sum = 0;
    for (i, &ch) in values[1..].iter().enumerate() {
        let mut digit = (ch - b'0' as i64) as i32;
        if (i as i64) % 2 == n % 2 { digit *= 2; if digit > 9 { digit -= 9; } }
        sum += digit;
    }
    if sum % 10 == 0 { 1 } else { 0 }
}
