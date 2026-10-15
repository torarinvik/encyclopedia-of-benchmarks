const MAX_LENGTH: usize = 4096;

/// Return whether any lowercase ASCII vowel appears in the input.
#[no_mangle]
pub extern "C" fn check_vowels(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length > 0 && values.is_null()) {
        return -1;
    }
    let data = if length == 0 { &[] } else { unsafe { std::slice::from_raw_parts(values, length) } };
    if data.iter().any(|&value| !(97..=122).contains(&value)) {
        return -1;
    }
    if data.iter().any(|&value| matches!(value, 97 | 101 | 105 | 111 | 117)) { 1 } else { 0 }
}
