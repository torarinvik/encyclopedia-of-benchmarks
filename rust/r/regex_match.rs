/// Direct recursive full-string matching for the . and * regular-expression subset.
fn regex_match_recursive(values: &[i64], text_length: usize, pattern_start: usize,
                         pattern_length: usize, text_index: usize, pattern_index: usize) -> bool {
    if pattern_index == pattern_length {
        return text_index == text_length;
    }
    let atom = values[pattern_start + pattern_index];
    if pattern_index + 1 < pattern_length && values[pattern_start + pattern_index + 1] == b'*' as i64 {
        if regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                  text_index, pattern_index + 2) {
            return true;
        }
        return text_index < text_length
            && (atom == b'.' as i64 || atom == values[2 + text_index])
            && regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                     text_index + 1, pattern_index);
    }
    text_index < text_length
        && (atom == b'.' as i64 || atom == values[2 + text_index])
        && regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                 text_index + 1, pattern_index + 1)
}

#[no_mangle]
pub extern "C" fn regex_match(values: *const i64, length: usize) -> i64 {
    if length < 2 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=12).contains(&values[0]) || !(0..=20).contains(&values[1]) {
        return -1;
    }
    let (text_length, pattern_length) = (values[0] as usize, values[1] as usize);
    if length != 2 + text_length + pattern_length {
        return -1;
    }
    let pattern_start = 2 + text_length;
    if values[2..pattern_start].iter().any(|&symbol| !(b'a' as i64..=b'z' as i64).contains(&symbol)) {
        return -1;
    }
    for index in 0..pattern_length {
        let symbol = values[pattern_start + index];
        if !((b'a' as i64..=b'z' as i64).contains(&symbol)
             || symbol == b'.' as i64 || symbol == b'*' as i64) {
            return -1;
        }
        if symbol == b'*' as i64
            && (index == 0 || values[pattern_start + index - 1] == b'*' as i64) {
            return -1;
        }
    }
    if regex_match_recursive(values, text_length, pattern_start, pattern_length, 0, 0) { 1 } else { 0 }
}
