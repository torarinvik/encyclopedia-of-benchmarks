const MAX_PARSEABLE_INPUT_LENGTH: usize = 258;

fn is_trim_byte(value: i64) -> bool { (0..=32).contains(&value) }
fn is_split_space(value: i64) -> bool { value == 32 || (9..=13).contains(&value) }

#[no_mangle]
pub unsafe extern "C" fn reverse_words_in_string(input: *const i64, length: usize,
                                                  output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=256).contains(&values[0]) || length != values[0] as usize + 1 { return -1; }
    let text_length = values[0] as usize;
    if values[1..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }

    let mut start = 0usize;
    let mut end = text_length;
    while start < end && is_trim_byte(values[start + 1]) { start += 1; }
    while end > start && is_trim_byte(values[end]) { end -= 1; }

    let mut output_length = 0usize;
    let mut word_count = 0usize;
    let mut position = start;
    while position < end {
        while position < end && is_split_space(values[position + 1]) { position += 1; }
        if position < end {
            let token_start = position;
            while position < end && !is_split_space(values[position + 1]) { position += 1; }
            output_length += position - token_start;
            if word_count > 0 { output_length += 1; }
            word_count += 1;
        }
    }
    if capacity < output_length || (output_length > 0 && output.is_null()) { return -2; }

    let mut written = 0usize;
    let mut emitted = 0usize;
    position = end;
    while position > start {
        while position > start && is_split_space(values[position]) { position -= 1; }
        if position > start {
            let token_end = position;
            while position > start && !is_split_space(values[position]) { position -= 1; }
            let token_start = position;
            if emitted > 0 { *output.add(written) = b' '; written += 1; }
            for i in token_start..token_end {
                *output.add(written) = values[i + 1] as u8;
                written += 1;
            }
            emitted += 1;
        }
    }
    written as i64
}
