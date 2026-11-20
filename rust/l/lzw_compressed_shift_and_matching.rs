const MAX_ALPHABET: usize = 16;
const MAX_PATTERN: usize = 32;
const MAX_CODES: usize = 32;
const MAX_DICTIONARY: usize = 47;
const MAX_EXPANDED: usize = 528;
const MAX_INPUT: usize = 67;
const MAX_OUTPUT_BYTES: usize = 4232;

fn store_i64_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    output[offset..offset + 8].copy_from_slice(&bytes);
}

#[no_mangle]
pub unsafe extern "C" fn lzw_compressed_shift_and_matching(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let alphabet_raw = *input;
    let pattern_raw = *input.add(1);
    let code_count_raw = *input.add(2);
    if alphabet_raw < 1 || alphabet_raw > MAX_ALPHABET as i64 || pattern_raw < 1 || pattern_raw > MAX_PATTERN as i64
            || code_count_raw < 0 || code_count_raw > MAX_CODES as i64 { return -1; }
    let alphabet_size = alphabet_raw as usize;
    let pattern_length = pattern_raw as usize;
    let code_count = code_count_raw as usize;
    if length != 3 + pattern_length + code_count { return -1; }
    let mut symbol_mask = [0u32; MAX_ALPHABET];
    for i in 0..pattern_length {
        let symbol = *input.add(3 + i);
        if symbol < 0 || symbol >= alphabet_raw { return -1; }
        symbol_mask[symbol as usize] |= 1u32 << i;
    }
    if code_count > 0 {
        let first_code = *input.add(3 + pattern_length);
        if first_code < 0 || first_code >= alphabet_raw { return -1; }
    }

    let mut phrase_length = [0usize; MAX_DICTIONARY];
    let mut first_symbol = [0u8; MAX_DICTIONARY];
    let mut phrase_mask = [0u32; MAX_DICTIONARY];
    let mut crossing_mask = [0u32; MAX_DICTIONARY];
    let mut ends_match = [false; MAX_DICTIONARY];
    let mut previous_match = [-1i32; MAX_DICTIONARY];
    let top_bit = 1u32 << (pattern_length - 1);
    for symbol in 0..alphabet_size {
        phrase_length[symbol] = 1;
        first_symbol[symbol] = symbol as u8;
        phrase_mask[symbol] = symbol_mask[symbol];
        if pattern_length > 1 && phrase_mask[symbol] & top_bit != 0 {
            crossing_mask[symbol] = 1u32 << (pattern_length - 2);
        }
        ends_match[symbol] = pattern_length == 1 && phrase_mask[symbol] & top_bit != 0;
    }

    let mut words = [0i64; 1 + MAX_EXPANDED];
    let mut occurrence_count = 0usize;
    let mut node_count = alphabet_size;
    let mut text_offset = 0usize;
    let mut state = 0u32;
    let mut previous_code = -1i32;
    for token in 0..code_count {
        let code_raw = *input.add(3 + pattern_length + token);
        let current_code: usize;
        if previous_code < 0 {
            current_code = code_raw as usize;
        } else {
            if code_raw < 0 || code_raw > node_count as i64 { return -1; }
            let appended: u8;
            if code_raw == node_count as i64 {
                appended = first_symbol[previous_code as usize];
                current_code = node_count;
            } else {
                current_code = code_raw as usize;
                appended = first_symbol[current_code];
            }
            if node_count >= MAX_DICTIONARY { return -1; }
            let node = node_count;
            node_count += 1;
            phrase_length[node] = phrase_length[previous_code as usize] + 1;
            first_symbol[node] = first_symbol[previous_code as usize];
            phrase_mask[node] = ((phrase_mask[previous_code as usize] << 1) | 1) & symbol_mask[appended as usize];
            crossing_mask[node] = crossing_mask[previous_code as usize];
            if phrase_length[node] < pattern_length && phrase_mask[node] & top_bit != 0 {
                crossing_mask[node] |= 1u32 << (pattern_length - phrase_length[node] - 1);
            }
            ends_match[node] = phrase_length[node] >= pattern_length && phrase_mask[node] & top_bit != 0;
            previous_match[node] = if ends_match[previous_code as usize] {
                previous_code
            } else { previous_match[previous_code as usize] };
        }

        let mut crossing = state & crossing_mask[current_code];
        while crossing != 0 {
            let highest = (u32::BITS - 1 - crossing.leading_zeros()) as usize;
            words[1 + occurrence_count] = text_offset as i64 - (highest as i64 + 1);
            occurrence_count += 1;
            crossing &= !(1u32 << highest);
        }
        let mut internal_nodes = [0usize; MAX_DICTIONARY];
        let mut internal_count = 0usize;
        let mut node = if ends_match[current_code] { current_code as i32 } else { previous_match[current_code] };
        while node >= 0 {
            internal_nodes[internal_count] = node as usize;
            internal_count += 1;
            node = previous_match[node as usize];
        }
        while internal_count > 0 {
            internal_count -= 1;
            node = internal_nodes[internal_count] as i32;
            words[1 + occurrence_count] = text_offset as i64 + phrase_length[node as usize] as i64 - pattern_length as i64;
            occurrence_count += 1;
        }

        let current_length = phrase_length[current_code];
        let shifted = if current_length >= pattern_length { 0 } else { state << current_length };
        let fresh = if current_length >= pattern_length {
            if pattern_length == 32 { u32::MAX } else { (1u32 << pattern_length) - 1 }
        } else { (1u32 << current_length) - 1 };
        state = (shifted | fresh) & phrase_mask[current_code];
        text_offset += current_length;
        previous_code = current_code as i32;
    }
    words[0] = occurrence_count as i64;
    let output_bytes = 8 * (1 + occurrence_count);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for word in 0..1 + occurrence_count { store_i64_le(&mut staged, 8 * word, words[word]); }
    core::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
