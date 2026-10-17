const MAX_TEXT_LENGTH: usize = 256;
const MAX_PATTERN_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 322;

#[no_mangle]
pub unsafe extern "C" fn kmp_all_occurrences(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let text_length_value = input[0];
    let pattern_length_value = input[1];
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length_value) ||
        !(1..=MAX_PATTERN_LENGTH as i64).contains(&pattern_length_value) { return -1; }
    let text_length = text_length_value as usize;
    let pattern_length = pattern_length_value as usize;
    if length != 2 + text_length + pattern_length { return -1; }
    if input[2..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    let pattern_offset = 2 + text_length;

    let mut prefix = [0usize; MAX_PATTERN_LENGTH];
    for i in 1..pattern_length {
        let mut matched = prefix[i - 1];
        while matched > 0 && input[pattern_offset + i] != input[pattern_offset + matched] {
            matched = prefix[matched - 1];
        }
        if input[pattern_offset + i] == input[pattern_offset + matched] { matched += 1; }
        prefix[i] = matched;
    }

    let mut matches = [0i64; MAX_TEXT_LENGTH];
    let mut match_count = 0usize;
    let mut matched = 0usize;
    for i in 0..text_length {
        while matched > 0 && input[2 + i] != input[pattern_offset + matched] {
            matched = prefix[matched - 1];
        }
        if input[2 + i] == input[pattern_offset + matched] { matched += 1; }
        if matched == pattern_length {
            matches[match_count] = (i + 1 - pattern_length) as i64;
            match_count += 1;
            matched = prefix[matched - 1];
        }
    }

    let output_bytes = match_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..match_count {
        let encoded = matches[i].to_le_bytes();
        std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(i * 8), 8);
    }
    output_bytes as i64
}
