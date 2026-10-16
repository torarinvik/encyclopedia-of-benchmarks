const MAX_TEXT_LENGTH: usize = 64;

#[no_mangle]
pub extern "C" fn validate_credit_card(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=MAX_TEXT_LENGTH + 1).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n = values[0];
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&n) || length != n as usize + 1 { return -1; }
    let text = &values[1..];
    if text.iter().any(|&code| !(0..=127).contains(&code)) { return -1; }
    if !(13..=16).contains(&n) { return 0; }
    if text.iter().any(|&code| !(48..=57).contains(&code)) { return 0; }
    let first = text[0] - 48;
    let second = text[1] - 48;
    if !(first == 4 || first == 5 || first == 6 ||
        (first == 3 && (second == 4 || second == 5 || second == 7))) { return 0; }
    let mut total = 0;
    for (index, &code) in text.iter().enumerate() {
        let mut digit = code - 48;
        if index % 2 == 0 {
            digit *= 2;
            if digit > 9 { digit -= 9; }
        }
        total += digit;
    }
    i64::from(total % 10 == 0)
}
