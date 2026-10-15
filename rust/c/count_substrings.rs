fn find_next(values: &[i64], text_length: usize, pattern_length: usize, pattern_start: usize, start: usize) -> Option<usize> {
    if start > text_length || pattern_length > text_length - start { return None; }
    let last = text_length - pattern_length;
    for position in start..=last {
        let mut offset = 0;
        while offset < pattern_length && values[2 + position + offset] == values[pattern_start + offset] { offset += 1; }
        if offset == pattern_length { return Some(position); }
    }
    None
}

#[no_mangle]
pub extern "C" fn count_substrings(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 4096 { return -1; }
    let text_length = values[0] as usize;
    let pattern_length = values[1] as usize;
    if length != 2 + text_length + pattern_length || values[2..].iter().any(|&v| !(0..=127).contains(&v)) { return -1; }
    if pattern_length == 0 { return text_length as i64 + 1; }
    let pattern_start = 2 + text_length;
    let mut count = 0i64;
    let mut start = 0;
    while let Some(position) = find_next(values, text_length, pattern_length, pattern_start, start) {
        count += 1;
        start = position + 1;
    }
    count
}
