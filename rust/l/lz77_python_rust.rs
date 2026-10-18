const MAX_INPUT_LENGTH: usize = 66;
const MAX_TEXT_LENGTH: usize = 64;
const MAX_OUTPUT_BYTES: usize = 1536;

fn put_i64_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn lz77_python_rust_compress(
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
    if values[1..].iter().any(|character| !(32..=126).contains(character)) { return -1; }
    if text_length > 0 {
        let final_character = values[text_length];
        if values[1..].iter().filter(|character| **character == final_character).count() != 1 {
            return -1;
        }
    }

    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    let mut token_count = 0_usize;
    let mut current = 0_usize;
    while current < text_length {
        let mut best_offset = 0_usize;
        let mut best_length = 0_usize;
        let search_start = current.saturating_sub(7);
        for candidate in search_start..current {
            let offset = current - candidate;
            let mut match_length = 0_usize;
            while current + match_length < text_length {
                let mut source = candidate + match_length;
                if source >= current { source = candidate + match_length % offset; }
                if values[source + 1] != values[current + match_length + 1] { break; }
                match_length += 1;
            }
            if match_length >= text_length - current { return -1; }
            if match_length >= best_length {
                best_offset = offset;
                best_length = match_length;
            }
        }

        if best_length >= text_length - current { return -1; }
        let indicator = values[current + best_length + 1];
        let offset = token_count * 24;
        put_i64_le(&mut staged, offset, best_offset as i64);
        put_i64_le(&mut staged, offset + 8, best_length as i64);
        put_i64_le(&mut staged, offset + 16, indicator);
        token_count += 1;
        current += best_length + 1;
    }

    let output_bytes = token_count * 24;
    if output_bytes > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || output_capacity < output_bytes { return -2; }
    if output_bytes > 0 {
        std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    }
    output_bytes as i64
}
