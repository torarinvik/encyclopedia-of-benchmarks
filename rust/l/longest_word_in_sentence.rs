fn is_ascii_whitespace(value: i64) -> bool {
    value == 32 || (9..=13).contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn longest_word_in_sentence(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 {
        return -1;
    }
    let text_length_value = *values;
    if !(0..=1024).contains(&text_length_value)
        || length != 1 + text_length_value as usize
    {
        return -1;
    }
    let text_length = text_length_value as usize;
    for index in 0..text_length {
        let byte = *values.add(index + 1);
        if !is_ascii_whitespace(byte) && !(33..=126).contains(&byte) {
            return -1;
        }
    }

    let mut best_start = 0usize;
    let mut best_length = 0usize;
    let mut index = 0usize;
    while index < text_length {
        if is_ascii_whitespace(*values.add(index + 1)) {
            index += 1;
            continue;
        }
        let start = index;
        while index < text_length && !is_ascii_whitespace(*values.add(index + 1)) {
            index += 1;
        }
        let word_length = index - start;
        if word_length > best_length {
            best_start = start;
            best_length = word_length;
        }
    }
    if best_length > output_capacity || (best_length > 0 && output.is_null()) {
        return -2;
    }
    for byte in 0..best_length {
        *output.add(byte) = *values.add(1 + best_start + byte) as u8;
    }
    best_length as i64
}
