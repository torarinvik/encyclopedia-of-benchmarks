/// Return the first ASCII byte match using Boyer-Moore's bad-character rule.
#[no_mangle]
pub extern "C" fn boyer_moore_search(input_values: *const i64, length: usize) -> i64 {
    if input_values.is_null() || length < 2 || length > 8194 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input_values, length) };
    if values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 4096 { return -1; }
    let text_length = values[0] as usize;
    let pattern_length = values[1] as usize;
    if length != 2 + text_length + pattern_length { return -1; }
    if values[2..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    if pattern_length == 0 { return 0; }
    if pattern_length > text_length { return -1; }

    let pattern_start = 2 + text_length;
    let mut last_occurrence = [-1isize; 128];
    for index in 0..pattern_length {
        last_occurrence[values[pattern_start + index] as usize] = index as isize;
    }
    let mut alignment = 0usize;
    while alignment <= text_length - pattern_length {
        let mut pattern_index = pattern_length;
        while pattern_index > 0 && values[pattern_start + pattern_index - 1] == values[2 + alignment + pattern_index - 1] {
            pattern_index -= 1;
        }
        if pattern_index == 0 { return alignment as i64; }
        let text_byte = values[2 + alignment + pattern_index - 1] as usize;
        let shift = (pattern_index as isize - 1 - last_occurrence[text_byte]).max(1) as usize;
        alignment += shift;
    }
    -1
}
