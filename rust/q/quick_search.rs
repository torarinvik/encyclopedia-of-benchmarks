/// Return the first ASCII byte match using a lookahead-byte shift table.
#[no_mangle]
pub extern "C" fn quick_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=512).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=255).contains(&values[0]) || !(0..=255).contains(&values[1]) { return -1; }
    let text_length = values[0] as usize;
    let pattern_length = values[1] as usize;
    if length != 2 + text_length + pattern_length ||
       values[2..].iter().any(|&byte| !(0..=127).contains(&byte)) { return -1; }
    if pattern_length == 0 { return 0; }
    if pattern_length > text_length { return -1; }

    let mut shift = [pattern_length; 128];
    let pattern_start = 2 + text_length;
    for index in 0..pattern_length {
        shift[values[pattern_start + index] as usize] = pattern_length - index;
    }

    let mut position = 0;
    while position <= text_length - pattern_length {
        let mut index = pattern_length;
        while index > 0 && values[2 + position + index - 1] == values[pattern_start + index - 1] {
            index -= 1;
        }
        if index == 0 { return position as i64; }
        if position + pattern_length >= text_length { break; }
        position += shift[values[2 + position + pattern_length] as usize];
    }
    -1
}
