const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;
const MAX_TRIE_NODES: usize = 33;
const MAX_TOKENS: usize = 32;
const MAX_OUTPUT_BYTES: usize = 776;

fn put_i64_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn lz78_run_length_transform(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if input_length != n + 1 { return -1; }
    if values[1..].iter().any(|&symbol| !(1..=3).contains(&symbol)) { return -1; }

    let mut transformed = [0_i64; MAX_TEXT_LENGTH];
    let mut transformed_length = 0_usize;
    let mut position = 0_usize;
    while position < n {
        let symbol = values[position + 1];
        let mut end = position + 1;
        while end < n && values[end + 1] == symbol { end += 1; }
        let run_length = end - position;
        let highest_bit = usize::BITS as usize - 1 - run_length.leading_zeros() as usize;
        for bit in (0..=highest_bit).rev() {
            transformed[transformed_length] = if (run_length >> bit) & 1 != 0 { symbol } else { 0 };
            transformed_length += 1;
        }
        position = end;
    }

    let mut children = [[0_usize; 4]; MAX_TRIE_NODES];
    let mut tokens = [[0_i64; 3]; MAX_TOKENS];
    let mut token_count = 0_usize;
    let mut text_position = 0_usize;
    let mut next_phrase_id = 1_usize;
    while text_position < transformed_length {
        let mut node = 0_usize;
        let mut end = text_position;
        while end < transformed_length {
            let child = children[node][transformed[end] as usize];
            if child == 0 { break; }
            node = child;
            end += 1;
        }
        if end == transformed_length {
            if node != 0 {
                tokens[token_count] = [node as i64, 0, 1];
                token_count += 1;
            }
            break;
        }
        let symbol = transformed[end] as usize;
        tokens[token_count] = [node as i64, symbol as i64, 0];
        token_count += 1;
        children[node][symbol] = next_phrase_id;
        next_phrase_id += 1;
        text_position = end + 1;
    }

    let output_bytes = 8 + 24 * token_count;
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    put_i64_le(&mut staged, 0, token_count as i64);
    for token in 0..token_count {
        for field in 0..3 {
            put_i64_le(&mut staged, 8 + 24 * token + 8 * field, tokens[token][field]);
        }
    }
    if output.is_null() || output_capacity < output_bytes { return -2; }
    if output_bytes > 0 { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes); }
    output_bytes as i64
}
