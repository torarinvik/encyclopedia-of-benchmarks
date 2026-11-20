const MAX_TEXT: usize = 512;
const MIN_PATTERN: usize = 2;
const MAX_PATTERN: usize = 64;
const MAX_INPUT: usize = 578;

#[no_mangle]
pub unsafe extern "C" fn not_so_naive_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -2; }
    let raw_text = *values;
    let raw_pattern = *values.add(1);
    if raw_text < 0 || raw_text > MAX_TEXT as i64 ||
        raw_pattern < MIN_PATTERN as i64 || raw_pattern > MAX_PATTERN as i64 { return -2; }
    let text_length = raw_text as usize;
    let pattern_length = raw_pattern as usize;
    if length != 2 + text_length + pattern_length { return -2; }
    let pattern_start = 2 + text_length;
    for i in 0..(text_length + pattern_length) {
        let byte = *values.add(2 + i);
        if byte < 0 || byte > 127 { return -2; }
    }
    if pattern_length > text_length { return -1; }

    let same_prefix = *values.add(pattern_start) == *values.add(pattern_start + 1);
    let mismatch_shift = if same_prefix { 2 } else { 1 };
    let post_check_shift = if same_prefix { 1 } else { 2 };
    let mut position = 0usize;
    let last_start = text_length - pattern_length;
    while position <= last_start {
        if *values.add(pattern_start + 1) != *values.add(2 + position + 1) {
            position += mismatch_shift;
            continue;
        }
        let mut pattern_index = 2usize;
        while pattern_index < pattern_length &&
            *values.add(pattern_start + pattern_index) == *values.add(2 + position + pattern_index) {
            pattern_index += 1;
        }
        if pattern_index == pattern_length && *values.add(pattern_start) == *values.add(2 + position) {
            return position as i64;
        }
        position += post_check_shift;
    }
    -1
}
