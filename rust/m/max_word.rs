const MAX_TEXT_LENGTH: usize = 512;
const MAX_INPUT_LENGTH: usize = MAX_TEXT_LENGTH + 2;

fn lower_ascii(value: u8) -> u8 {
    if value.is_ascii_uppercase() { value + (b'a' - b'A') } else { value }
}

#[no_mangle]
pub unsafe extern "C" fn max_word(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let raw = unsafe { std::slice::from_raw_parts(input, length) };
    if raw[0] < 1 || raw[0] > MAX_TEXT_LENGTH as i64 { return -1; }
    let text_length = raw[0] as usize;
    if length != 1 + text_length { return -1; }
    let mut text = [0u8; MAX_TEXT_LENGTH];
    for i in 0..text_length {
        let value = raw[i + 1];
        let is_letter = (65..=90).contains(&value) || (97..=122).contains(&value);
        if value == 32 {
            if i == 0 || i + 1 == text_length || text[i - 1] == b' ' { return -1; }
        } else if !is_letter || value == 73 {
            return -1;
        }
        text[i] = value as u8;
    }

    let mut starts = [0usize; MAX_TEXT_LENGTH];
    let mut lengths = [0usize; MAX_TEXT_LENGTH];
    let mut counts = [0usize; MAX_TEXT_LENGTH];
    let mut unique_count = 0usize;
    let mut start = 0usize;
    while start < text_length {
        let mut end = start;
        while end < text_length && text[end] != b' ' { end += 1; }
        let word_length = end - start;
        if word_length > 6 { return -1; }
        let mut found = unique_count;
        for key in 0..unique_count {
            if lengths[key] != word_length { continue; }
            let mut offset = 0usize;
            while offset < word_length &&
                lower_ascii(text[starts[key] + offset]) == lower_ascii(text[start + offset]) {
                offset += 1;
            }
            if offset == word_length { found = key; break; }
        }
        if found == unique_count {
            starts[unique_count] = start;
            lengths[unique_count] = word_length;
            counts[unique_count] = 1;
            unique_count += 1;
        } else {
            counts[found] += 1;
        }
        start = end + 1;
    }

    let mut winner = 0usize;
    for key in 1..unique_count {
        if counts[key] > counts[winner] { winner = key; }
    }
    let result_length = lengths[winner];
    if output_capacity < result_length || output.is_null() { return -2; }
    let single_word = unique_count == 1 && counts[0] == 1;
    for i in 0..result_length {
        let value = text[starts[winner] + i];
        unsafe { *output.add(i) = if single_word { value } else { lower_ascii(value) }; }
    }
    result_length as i64
}
