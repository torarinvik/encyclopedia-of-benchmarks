const MAX_TEXT_LENGTH: usize = 256;
const MAX_PATTERN_LENGTH: usize = 32;
const ALPHABET_SIZE: usize = 128;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH + 1;

fn next_state(pattern: &[i64], state: usize, symbol: i64) -> usize {
    if state < pattern.len() && symbol == pattern[state] {
        return state + 1;
    }
    for candidate in (1..=state).rev() {
        if pattern[candidate - 1] != symbol {
            continue;
        }
        let mut prefix_matches = true;
        for index in 0..candidate - 1 {
            if pattern[index] != pattern[state - candidate + index + 1] {
                prefix_matches = false;
                break;
            }
        }
        if prefix_matches {
            return candidate;
        }
    }
    0
}

fn store_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        unsafe { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn string_match_finite_automata(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    let raw_text_length = input[0];
    let raw_pattern_length = input[1];
    if raw_text_length < 0
        || raw_text_length > MAX_TEXT_LENGTH as i64
        || raw_pattern_length < 1
        || raw_pattern_length > MAX_PATTERN_LENGTH as i64
        || length != 2 + raw_text_length as usize + raw_pattern_length as usize
    {
        return -1;
    }
    let text_length = raw_text_length as usize;
    let pattern_length = raw_pattern_length as usize;
    let symbols = &input[2..];
    if symbols.iter().any(|&symbol| !(0..ALPHABET_SIZE as i64).contains(&symbol)) {
        return -1;
    }
    let text = &input[2..2 + text_length];
    let pattern = &input[2 + text_length..];

    let mut transitions = [[0i32; ALPHABET_SIZE]; MAX_PATTERN_LENGTH + 1];
    for state in 0..=pattern_length {
        for symbol in 0..ALPHABET_SIZE {
            transitions[state][symbol] = next_state(pattern, state, symbol as i64) as i32;
        }
    }

    let mut matches = [0i32; MAX_TEXT_LENGTH];
    let mut match_count = 0usize;
    let mut state = 0usize;
    for (index, &symbol) in text.iter().enumerate() {
        state = transitions[state][symbol as usize] as usize;
        if state == pattern_length {
            matches[match_count] = (index + 1 - pattern_length) as i32;
            match_count += 1;
        }
    }

    let byte_count = 4 * match_count;
    if output.is_null() || capacity < byte_count {
        return -2;
    }
    for index in 0..match_count {
        store_i32_le(output, index * 4, matches[index]);
    }
    byte_count as i64
}
