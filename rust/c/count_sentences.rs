/// Count non-overlapping PHP-style sentence-regex matches in bounded ASCII.
const MAX_TEXT_LENGTH: usize = 4096;

fn is_trim_byte(value: u8) -> bool {
    matches!(value, 0 | 9 | 10 | 11 | 13 | 32)
}
fn is_regex_space(value: u8) -> bool {
    (9..=13).contains(&value) || value == 32
}
fn is_word_byte(value: u8) -> bool {
    value.is_ascii_alphanumeric() || value == b'_'
}
fn is_terminator(value: u8) -> bool {
    value == b'.' || value == b'!' || value == b'?'
}
fn is_eligible_predecessor(value: u8) -> bool {
    !is_regex_space(value) && value != b'|' && value != b'^' && value != b'.'
}

#[no_mangle]
pub extern "C" fn count_sentences(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_TEXT_LENGTH + 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 0 || values[0] > MAX_TEXT_LENGTH as i64 || length != values[0] as usize + 1 { return -1; }
    let text_length = values[0] as usize;
    let mut text = [0u8; MAX_TEXT_LENGTH];
    for index in 0..text_length {
        if !(0..=127).contains(&values[index + 1]) { return -1; }
        text[index] = values[index + 1] as u8;
    }

    let mut begin = 0;
    let mut end = text_length;
    while begin < end && is_trim_byte(text[begin]) { begin += 1; }
    while end > begin && is_trim_byte(text[end - 1]) { end -= 1; }
    let mut cursor = begin;
    let mut count = 0i64;
    while cursor + 1 < end {
        let mut found = false;
        for index in cursor..end - 1 {
            if is_eligible_predecessor(text[index]) && is_terminator(text[index + 1]) &&
                (index + 2 == end || !is_word_byte(text[index + 2])) {
                count += 1;
                cursor = index + 2;
                found = true;
                break;
            }
        }
        if !found { break; }
    }
    count
}
