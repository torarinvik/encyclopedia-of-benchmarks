const MAX_INPUT_LENGTH: usize = 66;
const MAX_TEXT_LENGTH: usize = 64;
const MAX_OUTPUT_BYTES: usize = 1024;

fn put_i64_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn lz78_compress(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&values[0]) { return -1; }
    let text_length = values[0] as usize;
    if input_length != 1 + text_length { return -1; }
    for &character in &values[1..] {
        if !(32..=126).contains(&character) { return -1; }
    }

    let mut edge_parent = [0_i64; MAX_TEXT_LENGTH];
    let mut edge_character = [0_i64; MAX_TEXT_LENGTH];
    let mut dictionary_size = 0_usize;
    let mut tokens = [(0_i64, 0_i64); MAX_TEXT_LENGTH];
    let mut token_count = 0_usize;
    let mut current_index = 0_i64;
    for &character in &values[1..] {
        let mut found = None;
        for edge in 0..dictionary_size {
            if edge_parent[edge] == current_index && edge_character[edge] == character {
                found = Some(edge);
                break;
            }
        }
        if let Some(edge) = found {
            current_index = edge as i64 + 1;
        } else {
            tokens[token_count] = (current_index, character);
            token_count += 1;
            edge_parent[dictionary_size] = current_index;
            edge_character[dictionary_size] = character;
            dictionary_size += 1;
            current_index = 0;
        }
    }
    if current_index != 0 {
        tokens[token_count] = (current_index, 0);
        token_count += 1;
    }

    let output_bytes = 16 * token_count;
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    for token in 0..token_count {
        put_i64_le(&mut staged, 16 * token, tokens[token].0);
        put_i64_le(&mut staged, 16 * token + 8, tokens[token].1);
    }
    if output.is_null() || output_capacity < output_bytes { return -2; }
    if output_bytes > 0 { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes); }
    output_bytes as i64
}
