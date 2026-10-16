const MAX_TEXT_LENGTH: usize = 128;
const MAX_PATTERN_LENGTH: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn substring_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 195 { return -2; }
    let input = std::slice::from_raw_parts(values, length);
    let (text_length, pattern_length) = (input[0], input[1]);
    if text_length < 0 || text_length > MAX_TEXT_LENGTH as i64 ||
        pattern_length < 0 || pattern_length > MAX_PATTERN_LENGTH as i64 ||
        length != 2 + text_length as usize + pattern_length as usize { return -2; }
    let text_start = 2;
    let pattern_start = text_start + text_length as usize;
    if input[text_start..].iter().any(|&byte| !(1..=127).contains(&byte)) { return -2; }
    let (mut text_index, mut pattern_index) = (0usize, 0usize);
    let mut match_start = -1i64;
    while text_index < text_length as usize {
        let expected = if pattern_index < pattern_length as usize {
            input[pattern_start + pattern_index]
        } else { 0 };
        if input[text_start + text_index] == expected {
            if match_start == -1 { match_start = text_index as i64; }
            pattern_index += 1;
            if pattern_index == pattern_length as usize { return match_start; }
            text_index += 1;
        } else {
            match_start = -1;
            pattern_index = 0;
            text_index += 1;
        }
    }
    -1
}
