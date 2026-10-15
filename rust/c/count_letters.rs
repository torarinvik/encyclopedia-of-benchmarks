fn lowercase_ascii_letter(value: i64) -> i64 {
    if (65..=90).contains(&value) { value + 32 } else { value }
}

#[no_mangle]
pub unsafe extern "C" fn count_letters(raw: *const i64, length: usize) -> i64 {
    if raw.is_null() || length < 2 { return -1; }
    let input = std::slice::from_raw_parts(raw, length);
    if input[1] < 0 || input[1] > 256 { return -1; }
    let text_length = input[1] as usize;
    if length != text_length + 2 { return -1; }
    let query = lowercase_ascii_letter(input[0]);
    if !(97..=122).contains(&query) { return -1; }
    let mut count = 0i64;
    for value in &input[2..] {
        if !((97..=122).contains(value) || (65..=90).contains(value)) { return -1; }
        if lowercase_ascii_letter(*value) == query { count += 1; }
    }
    count
}
