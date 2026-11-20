const MAX_TEXT_LENGTH: usize = 4096;
const MAX_PATTERN_LENGTH: usize = 128;
const MAX_BUCKETS: usize = 64;
const MAX_INPUT_LENGTH: usize = 4227;

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let (text_length64, pattern_length64) = (input[0], input[1]);
    if text_length64 < 0 || text_length64 > MAX_TEXT_LENGTH as i64
        || pattern_length64 < 1 || pattern_length64 > MAX_PATTERN_LENGTH as i64 { return Err(()); }
    let (text_length, pattern_length) = (text_length64 as usize, pattern_length64 as usize);
    if input.len() != 2 + text_length + pattern_length { return Err(()); }

    let mut text = [0u8; MAX_TEXT_LENGTH];
    let mut pattern = [0u8; MAX_PATTERN_LENGTH];
    for i in 0..text_length {
        let symbol = input[2 + i];
        if !(0..=3).contains(&symbol) { return Err(()); }
        text[i] = symbol as u8;
    }
    let pattern_offset = 2 + text_length;
    for i in 0..pattern_length {
        let symbol = input[pattern_offset + i];
        if !(0..=3).contains(&symbol) { return Err(()); }
        pattern[i] = symbol as u8;
    }

    let mut factor_length = 1usize;
    let mut bucket_count = 4usize;
    while bucket_count * 4 <= pattern_length {
        bucket_count *= 4;
        factor_length += 1;
    }
    let factor_count = pattern_length - factor_length + 1;
    let mut factor_power = 1usize;
    for _ in 1..factor_length { factor_power *= 4; }
    let mut heads = [-1i16; MAX_BUCKETS];
    let mut next_position = [-1i16; MAX_PATTERN_LENGTH];
    let mut code = 0usize;
    for i in 0..factor_length { code = code * 4 + pattern[i] as usize; }
    for position in 0..factor_count {
        if position > 0 {
            code = (code - pattern[position - 1] as usize * factor_power) * 4
                + pattern[position + factor_length - 1] as usize;
        }
        next_position[position] = heads[code];
        heads[code] = position as i16;
    }
    if text_length < pattern_length { return Ok(0); }

    let shift = pattern_length - factor_length + 1;
    let mut match_count = 0i64;
    let mut offset_sum = 0i64;
    let mut offset_xor = 0i64;
    let mut sample_start = 0usize;
    while sample_start <= text_length - factor_length {
        let mut text_code = 0usize;
        for offset in 0..factor_length { text_code = text_code * 4 + text[sample_start + offset] as usize; }
        let mut pattern_position = heads[text_code];
        while pattern_position >= 0 {
            let candidate = sample_start as isize - pattern_position as isize;
            if candidate >= 0 && candidate as usize <= text_length - pattern_length {
                let start = candidate as usize;
                let mut matches = true;
                for offset in 0..pattern_length {
                    if text[start + offset] != pattern[offset] { matches = false; break; }
                }
                if matches {
                    match_count += 1;
                    offset_sum += start as i64;
                    offset_xor ^= start as i64;
                }
            }
            pattern_position = next_position[pattern_position as usize];
        }
        sample_start += shift;
    }
    Ok((match_count << 36) | (offset_sum << 12) | offset_xor)
}

#[no_mangle]
pub unsafe extern "C" fn alpha_skip_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
