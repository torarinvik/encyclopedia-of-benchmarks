const MAX_LENGTH: usize = 4096;

fn is_ascii_word(value: i64) -> bool {
    (value >= 97 && value <= 122)
        || (value >= 65 && value <= 90)
        || (value >= 48 && value <= 57)
}

#[no_mangle]
pub extern "C" fn check_kebab_case(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -2; }
    let input = if length == 0 { &[][..] } else { unsafe { std::slice::from_raw_parts(values, length) } };
    if input.iter().any(|&value| !(32..=126).contains(&value)) { return -2; }
    if input.contains(&95) { return 0; }
    for index in 1..input.len().saturating_sub(1) {
        if input[index] == 45 && is_ascii_word(input[index - 1]) && is_ascii_word(input[index + 1]) {
            return 1;
        }
    }
    0
}
