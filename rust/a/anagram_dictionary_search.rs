const MAX_WORDS: usize = 16;
const MAX_WORD_LENGTH: usize = 16;

fn is_anagram(query: &[i64], word: &[i64]) -> bool {
    if query.len() != word.len() { return false; }
    let mut counts = [0i32; 26];
    for index in 0..query.len() { counts[(query[index] - 97) as usize] += 1; counts[(word[index] - 97) as usize] -= 1; }
    counts.iter().all(|&count| count == 0)
}

#[no_mangle]
pub unsafe extern "C" fn anagram_dictionary_search(input: *const i64, length: usize,
                                                     output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_WORDS as i64 || values[1] < 0 || values[1] > MAX_WORD_LENGTH as i64 { return -1; }
    let word_count = values[0] as usize;
    let query_length = values[1] as usize;
    if 2 + query_length > length || values[2..2 + query_length].iter().any(|&c| !(97..=122).contains(&c)) { return -1; }
    if output.is_null() { return -2; }
    let output = std::slice::from_raw_parts_mut(output, capacity);
    let mut offset = 2 + query_length;
    let mut out = 0usize;
    for _ in 0..word_count {
        if offset >= length || values[offset] < 1 || values[offset] > MAX_WORD_LENGTH as i64 { return -1; }
        let word_length = values[offset] as usize;
        offset += 1;
        if offset + word_length > length || values[offset..offset + word_length].iter().any(|&c| !(97..=122).contains(&c)) { return -1; }
        if is_anagram(&values[2..2 + query_length], &values[offset..offset + word_length]) {
            for &byte in &values[offset..offset + word_length] {
                if out >= capacity { return -2; }
                output[out] = byte as u8; out += 1;
            }
            if out >= capacity { return -2; }
            output[out] = b'\n'; out += 1;
        }
        offset += word_length;
    }
    if offset != length { return -1; }
    if out >= capacity { return -2; }
    output[out] = 0;
    (out + 1) as i64
}
