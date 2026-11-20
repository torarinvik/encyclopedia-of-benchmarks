const MAX_TEXT: usize = 64;
const MAX_PATTERN: usize = 16;
const MAX_ALPHABET: usize = 16;
const MAX_PARSEABLE_INPUT: usize = 84;
const MAX_OUTPUT_BYTES: usize = 520;

fn store_word(output: &mut [u8; MAX_OUTPUT_BYTES], word: usize, value: i64) {
    let bytes = value.to_le_bytes();
    output[word * 8..word * 8 + 8].copy_from_slice(&bytes);
}

fn pattern_pair_matches(pattern: &[i64; MAX_PATTERN], previous: &[i32; MAX_PATTERN],
                        previous_at: &[i32; MAX_PATTERN], current: usize,
                        prefix_position: usize) -> bool {
    let prior = previous[current];
    if prior < 0 || current as i32 - prior > prefix_position as i32 {
        return previous_at[prefix_position] < 0;
    }
    let distance = current - prior as usize;
    pattern[prefix_position] == pattern[prefix_position - distance]
}

fn text_symbol_matches(text: &[i64], text_position: usize, pattern_position: usize,
                       previous: &[i32; MAX_PATTERN],
                       last_text: &[i32; MAX_ALPHABET]) -> bool {
    let prior = previous[pattern_position];
    let symbol = text[text_position] as usize;
    if prior < 0 {
        return last_text[symbol] < (text_position - pattern_position) as i32;
    }
    let distance = pattern_position - prior as usize;
    text[text_position] == text[text_position - distance]
}

#[no_mangle]
pub unsafe extern "C" fn parameterized_pattern_matching_kmp(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let m_value = values[1];
    let alphabet_value = values[2];
    if n_value < 0 || n_value > MAX_TEXT as i64 ||
        m_value < 1 || m_value > MAX_PATTERN as i64 ||
        alphabet_value < 1 || alphabet_value > MAX_ALPHABET as i64 { return -1; }
    let n = n_value as usize;
    let m = m_value as usize;
    let alphabet_size = alphabet_value as i64;
    if length != 3 + n + m || values[3..].iter().any(|&x| x < 0 || x >= alphabet_size) {
        return -1;
    }
    let text = &values[3..3 + n];
    let pattern_values = &values[3 + n..];
    let mut pattern = [0i64; MAX_PATTERN];
    pattern[..m].copy_from_slice(pattern_values);
    let mut previous = [-1i32; MAX_PATTERN];
    let mut previous_at = [-1i32; MAX_PATTERN];
    let mut last_pattern = [-1i32; MAX_ALPHABET];
    for index in 0..m {
        let symbol = pattern[index] as usize;
        previous[index] = last_pattern[symbol];
        previous_at[index] = previous[index];
        last_pattern[symbol] = index as i32;
    }
    let mut failure = [0i32; MAX_PATTERN];
    for current in 1..m {
        let mut matched = failure[current - 1] as usize;
        while matched > 0 && !pattern_pair_matches(&pattern, &previous, &previous_at,
                                                   current, matched) {
            matched = failure[matched - 1] as usize;
        }
        if pattern_pair_matches(&pattern, &previous, &previous_at, current, matched) {
            matched += 1;
        }
        failure[current] = matched as i32;
    }

    let mut last_text = [-1i32; MAX_ALPHABET];
    let mut matches = [0i64; MAX_TEXT];
    let mut match_count = 0usize;
    let mut matched = 0usize;
    if m <= n {
        for text_position in 0..n {
            loop {
                if text_symbol_matches(text, text_position, matched, &previous, &last_text) {
                    matched += 1;
                    if matched == m {
                        matches[match_count] = (text_position + 1 - m) as i64;
                        match_count += 1;
                        matched = failure[m - 1] as usize;
                    }
                    break;
                }
                if matched == 0 { break; }
                matched = failure[matched - 1] as usize;
            }
            last_text[text[text_position] as usize] = text_position as i32;
        }
    }
    let output_bytes = 8 * (match_count + 1);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    store_word(&mut staged, 0, match_count as i64);
    for index in 0..match_count { store_word(&mut staged, index + 1, matches[index]); }
    for index in 0..output_bytes { *output.add(index) = staged[index]; }
    output_bytes as i64
}
