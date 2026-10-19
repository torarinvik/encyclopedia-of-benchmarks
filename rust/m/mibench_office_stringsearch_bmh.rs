/// Modified derivative of MiBench bmhsrch.c; public domain by Raymond Gardner (7/92).
const MAX_TEXT: usize = 128;
const MAX_PATTERN: usize = 32;
const MAX_INPUT: usize = 162;

#[no_mangle]
pub unsafe extern "C" fn mibench_office_stringsearch_bmh(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let text_len_value = *input;
    let pattern_len_value = *input.add(1);
    if text_len_value < 0 || text_len_value > MAX_TEXT as i64
        || pattern_len_value < 1 || pattern_len_value > MAX_PATTERN as i64 { return -1; }
    let text_len = text_len_value as usize;
    let pattern_len = pattern_len_value as usize;
    if length != 2 + text_len + pattern_len { return -1; }
    let mut text = [0u8; MAX_TEXT];
    let mut pattern = [0u8; MAX_PATTERN];
    for i in 0..text_len + pattern_len {
        let value = *input.add(2 + i);
        if !(32..=126).contains(&value) { return -1; }
        if i < text_len { text[i] = value as u8; }
        else { pattern[i - text_len] = value as u8; }
    }
    let mut shift = [pattern_len; 256];
    for i in 0..pattern_len - 1 { shift[pattern[i] as usize] = pattern_len - i - 1; }
    let mut match_offset: i64 = -1;
    if pattern_len <= text_len {
        let mut start = 0usize;
        while start <= text_len - pattern_len {
            let mut j = pattern_len;
            while j > 0 && text[start + j - 1] == pattern[j - 1] { j -= 1; }
            if j == 0 { match_offset = start as i64; break; }
            start += shift[text[start + pattern_len - 1] as usize];
        }
    }
    if output.is_null() || output_capacity < 8 { return -2; }
    let bits = match_offset as u64;
    for i in 0..8 { *output.add(i) = (bits >> (8 * i)) as u8; }
    8
}
