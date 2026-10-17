use std::slice;

const MAX_INPUT: usize = 258;

#[no_mangle]
pub unsafe extern "C" fn is_strong_password(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = slice::from_raw_parts(input, length);
    let minimum_length = values[0];
    let text_length_value = values[1];
    if !(0..=256).contains(&minimum_length) || !(0..=256).contains(&text_length_value) { return -1; }
    let text_length = text_length_value as usize;
    if length != text_length + 2 { return -1; }

    let (mut has_uppercase, mut has_lowercase, mut has_digit, mut has_punctuation) = (false, false, false, false);
    for &value in &values[2..] {
        if !(0..=127).contains(&value) { return -1; }
        has_uppercase |= (65..=90).contains(&value);
        has_lowercase |= (97..=122).contains(&value);
        has_digit |= (48..=57).contains(&value);
        has_punctuation |= (33..=47).contains(&value) || (58..=64).contains(&value) ||
            (91..=96).contains(&value) || (123..=126).contains(&value);
    }
    if text_length_value < minimum_length { return 0; }
    if has_uppercase && has_lowercase && has_digit && has_punctuation { 1 } else { 0 }
}
