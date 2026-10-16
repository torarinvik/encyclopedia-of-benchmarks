const MAX_INPUT_LENGTH: usize = 4096;
const MAX_WORDS: usize = 2049;

fn is_ascii_whitespace(byte: i64) -> bool {
    byte == 32 || (9..=13).contains(&byte)
}

#[no_mangle]
pub unsafe extern "C" fn remove_duplicate_words(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH + 1 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] as usize > MAX_INPUT_LENGTH || length != input[0] as usize + 1 {
        return -1;
    }
    let text = &input[1..];
    if text.iter().any(|byte| !(0..=127).contains(byte)) { return -1; }

    let mut starts = [0_usize; MAX_WORDS];
    let mut word_lengths = [0_usize; MAX_WORDS];
    let mut word_count = 0;
    let mut token_start = 0;
    let mut output_length = 0;
    for boundary in 0..=text.len() {
        if boundary < text.len() && !is_ascii_whitespace(text[boundary]) { continue; }
        let word_length = boundary - token_start;
        let mut duplicate = false;
        for previous in 0..word_count {
            if word_lengths[previous] == word_length &&
                text[starts[previous]..starts[previous] + word_length] == text[token_start..boundary] {
                duplicate = true;
                break;
            }
        }
        if !duplicate {
            if word_count == MAX_WORDS { return -1; }
            starts[word_count] = token_start;
            word_lengths[word_count] = word_length;
            if word_count > 0 { output_length += 1; }
            output_length += word_length;
            word_count += 1;
        }
        if boundary < text.len() { token_start = boundary + 1; }
    }
    if output_length > output_capacity || (output_length > 0 && output.is_null()) { return -2; }

    let mut written = 0;
    for word in 0..word_count {
        if word > 0 { *output.add(written) = b' '; written += 1; }
        for offset in 0..word_lengths[word] {
            *output.add(written) = text[starts[word] + offset] as u8;
            written += 1;
        }
    }
    written as i64
}
