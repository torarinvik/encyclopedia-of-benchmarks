const MAX_TEXT: usize = 24;
const MAX_PATTERN: usize = 8;
const ALPHABET: usize = 16;
const MAX_OUTPUT_BYTES: usize = 200;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

fn predecessor_code(symbols: &[i64], code: &mut [i64]) {
    let mut last = [-1i64; ALPHABET];
    for (index, &symbol) in symbols.iter().enumerate() {
        let slot = symbol as usize;
        code[index] = if last[slot] < 0 { 0 } else { index as i64 - last[slot] };
        last[slot] = index as i64;
    }
}

#[no_mangle]
pub unsafe extern "C" fn parameterized_pattern_matching(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > 2 + MAX_TEXT + MAX_PATTERN {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_TEXT as i64 ||
        values[1] < 1 || values[1] > MAX_PATTERN as i64 {
        return -1;
    }
    let text_length = values[0] as usize;
    let pattern_length = values[1] as usize;
    if length != 2 + text_length + pattern_length ||
        values[2..].iter().any(|&value| value < 0 || value >= ALPHABET as i64) {
        return -1;
    }

    let text = &values[2..2 + text_length];
    let pattern = &values[2 + text_length..];
    let mut pattern_code = [0i64; MAX_PATTERN];
    predecessor_code(pattern, &mut pattern_code);
    let mut matches = [0usize; MAX_TEXT];
    let mut match_count = 0usize;
    if pattern_length <= text_length {
        for start in 0..=text_length - pattern_length {
            let mut window_code = [0i64; MAX_PATTERN];
            predecessor_code(&text[start..start + pattern_length], &mut window_code);
            if pattern_code[..pattern_length] == window_code[..pattern_length] {
                matches[match_count] = start;
                match_count += 1;
            }
        }
    }
    let output_bytes = 8 * (match_count + 1);
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    store_i64_le(staged.as_mut_ptr(), 0, match_count as i64);
    for index in 0..match_count {
        store_i64_le(staged.as_mut_ptr(), 8 * (index + 1), matches[index] as i64);
    }
    for index in 0..output_bytes {
        *output.add(index) = staged[index];
    }
    output_bytes as i64
}
