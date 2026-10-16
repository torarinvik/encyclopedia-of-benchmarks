/// Apply bounded byte-pair merges with first-seen tie-breaking.
#[no_mangle]
pub extern "C" fn bpe_tokenizer(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > 515 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let merge_count_value = values[0];
    let byte_count_value = values[1];
    if !(0..=32).contains(&merge_count_value) || !(0..=512).contains(&byte_count_value)
        || length != byte_count_value as usize + 2 { return -2; }
    let byte_count = byte_count_value as usize;
    let mut tokens = [0_i64; 512];
    let mut next_tokens = [0_i64; 512];
    for index in 0..byte_count {
        if !(0..=255).contains(&values[index + 2]) { return -2; }
        tokens[index] = values[index + 2];
    }
    let mut token_count = byte_count;
    for step in 0..merge_count_value as usize {
        if token_count <= 1 { break; }
        let mut pair_left = [0_i64; 511];
        let mut pair_right = [0_i64; 511];
        let mut pair_frequency = [0_i64; 511];
        let mut unique_pairs = 0;
        for index in 0..token_count - 1 {
            let mut pair_index = 0;
            while pair_index < unique_pairs
                && (pair_left[pair_index] != tokens[index] || pair_right[pair_index] != tokens[index + 1]) {
                pair_index += 1;
            }
            if pair_index == unique_pairs {
                pair_left[pair_index] = tokens[index];
                pair_right[pair_index] = tokens[index + 1];
                pair_frequency[pair_index] = 1;
                unique_pairs += 1;
            } else {
                pair_frequency[pair_index] += 1;
            }
        }
        let mut best = 0;
        for index in 1..unique_pairs {
            if pair_frequency[index] > pair_frequency[best] { best = index; }
        }
        if unique_pairs == 0 || pair_frequency[best] == 1 { break; }
        let mut next_count = 0;
        let mut index = 0;
        while index < token_count {
            if index + 1 < token_count && tokens[index] == pair_left[best]
                && tokens[index + 1] == pair_right[best] {
                next_tokens[next_count] = 256 + step as i64;
                next_count += 1;
                index += 2;
            } else {
                next_tokens[next_count] = tokens[index];
                next_count += 1;
                index += 1;
            }
        }
        tokens[..next_count].copy_from_slice(&next_tokens[..next_count]);
        token_count = next_count;
    }
    if token_count > output_capacity / 2 || (token_count != 0 && output.is_null()) { return -2; }
    for index in 0..token_count {
        let token = tokens[index] as u16;
        unsafe {
            *output.add(2 * index) = token as u8;
            *output.add(2 * index + 1) = (token >> 8) as u8;
        }
    }
    token_count as i64
}
