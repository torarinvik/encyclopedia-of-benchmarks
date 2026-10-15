#[no_mangle]
pub extern "C" fn horspool_search(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 2 {
        return -2;
    }
    let values = unsafe { std::slice::from_raw_parts(packed, length) };
    let text_length = values[0];
    let pattern_length = values[1];
    if !(0..=512).contains(&text_length)
        || !(0..=64).contains(&pattern_length)
        || length != text_length as usize + pattern_length as usize + 2
    {
        return -2;
    }
    let text_length = text_length as usize;
    let pattern_length = pattern_length as usize;
    let pattern_start = 2 + text_length;
    let text = &values[2..pattern_start];
    let pattern = &values[pattern_start..];
    if text.iter().chain(pattern).any(|&byte| !(0..=127).contains(&byte)) {
        return -2;
    }
    if pattern_length == 0 || pattern_length > text_length {
        return -1;
    }
    let mut shifts = [pattern_length; 128];
    for index in (0..pattern_length - 1).rev() {
        let byte = pattern[index] as usize;
        if shifts[byte] == pattern_length {
            shifts[byte] = pattern_length - 1 - index;
        }
    }
    let mut end = pattern_length - 1;
    while end < text_length {
        let mut offset = 0;
        while offset < pattern_length && pattern[pattern_length - 1 - offset] == text[end - offset] {
            offset += 1;
        }
        if offset == pattern_length {
            return (end - pattern_length + 1) as i64;
        }
        end += shifts[text[end] as usize];
    }
    -1
}
