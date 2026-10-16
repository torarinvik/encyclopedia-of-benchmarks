const MAX_WIDTH: usize = 64;
const MAX_TEXT_BYTES: usize = 512;
const MAX_WORDS: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + MAX_TEXT_BYTES + 1;
const MAX_OUTPUT_BYTES: usize = MAX_WORDS * MAX_WIDTH + MAX_WORDS;

#[no_mangle]
pub unsafe extern "C" fn text_justification(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let raw = unsafe { std::slice::from_raw_parts(input, length) };
    if raw[0] < 1 || raw[0] > MAX_WIDTH as i64 || raw[1] < 0 || raw[1] > MAX_TEXT_BYTES as i64 {
        return -1;
    }
    let width = raw[0] as usize;
    let text_length = raw[1] as usize;
    if length != 2 + text_length {
        return -1;
    }
    let mut text = [0u8; MAX_TEXT_BYTES];
    for i in 0..text_length {
        let value = raw[i + 2];
        if value != 32 && !(33..=126).contains(&value) {
            return -1;
        }
        text[i] = value as u8;
    }
    let mut starts = [0usize; MAX_WORDS];
    let mut lengths = [0usize; MAX_WORDS];
    let mut word_count = 0usize;
    let mut pos = 0usize;
    while pos < text_length {
        while pos < text_length && text[pos] == b' ' { pos += 1; }
        if pos == text_length { break; }
        let start = pos;
        while pos < text_length && text[pos] != b' ' { pos += 1; }
        let word_len = pos - start;
        if word_count == MAX_WORDS || word_len > width { return -1; }
        starts[word_count] = start;
        lengths[word_count] = word_len;
        word_count += 1;
    }

    let mut result = [0u8; MAX_OUTPUT_BYTES];
    let mut result_len = 0usize;
    let (mut line_start, mut line_end, mut letters) = (0usize, 0usize, 0usize);
    let mut first_line = true;
    for word in 0..word_count {
        if letters + lengths[word] + (line_end - line_start) <= width {
            letters += lengths[word];
            line_end += 1;
            continue;
        }
        if !first_line { result[result_len] = b'\n'; result_len += 1; }
        first_line = false;
        let count = line_end - line_start;
        if count == 1 {
            for i in 0..lengths[line_start] { result[result_len] = text[starts[line_start] + i]; result_len += 1; }
            for _ in lengths[line_start]..width { result[result_len] = b' '; result_len += 1; }
        } else {
            let gaps = count - 1;
            let spaces = width - letters;
            let base = spaces / gaps;
            let extra = spaces % gaps;
            for item in 0..count {
                let current = line_start + item;
                for i in 0..lengths[current] { result[result_len] = text[starts[current] + i]; result_len += 1; }
                if item + 1 < count {
                    let gap_spaces = if item < extra { base + 1 } else { base };
                    for _ in 0..gap_spaces { result[result_len] = b' '; result_len += 1; }
                }
            }
        }
        line_start = word;
        line_end = word + 1;
        letters = lengths[word];
    }
    if !first_line { result[result_len] = b'\n'; result_len += 1; }
    for item in line_start..line_end {
        if item != line_start { result[result_len] = b' '; result_len += 1; }
        for i in 0..lengths[item] { result[result_len] = text[starts[item] + i]; result_len += 1; }
    }
    let trailing = width - letters - (line_end - line_start) + 1;
    for _ in 0..trailing { result[result_len] = b' '; result_len += 1; }
    if output_capacity < result_len || (result_len != 0 && output.is_null()) { return -2; }
    for i in 0..result_len { unsafe { *output.add(i) = result[i]; } }
    result_len as i64
}
