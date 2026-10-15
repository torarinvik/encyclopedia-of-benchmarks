/// Count literal-space-delimited words and requested-word matches.
fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub extern "C" fn word_count(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 2 || length > 1050 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 0 || values[0] > 999 { return -1; }
    let text_length = values[0] as usize;
    let query_index = 1 + text_length;
    if query_index >= length || values[query_index] < 0 || values[query_index] > 49 { return -1; }
    let query_length = values[query_index] as usize;
    if length != query_index + 1 + query_length
        || values[1..query_index].iter().any(|&value| !(1..=127).contains(&value))
        || values[query_index + 1..].iter().any(|&value| !(1..=127).contains(&value)) { return -1; }
    let mut total = 0usize;
    let mut matches = 0usize;
    let mut start = 0usize;
    for finish in 0..=text_length {
        if finish == text_length || values[1 + finish] == 32 {
            let token_length = finish - start;
            if token_length > 49 { return -1; }
            if total >= 20 { return -2; }
            if token_length == query_length && values[1 + start..1 + finish] == values[query_index + 1..query_index + 1 + query_length] {
                matches += 1;
            }
            total += 1;
            start = finish + 1;
        }
    }
    if output.is_null() || output_capacity < 16 { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, 16) };
    store_i64_le(output, 0, total as i64);
    store_i64_le(output, 8, matches as i64);
    16
}
