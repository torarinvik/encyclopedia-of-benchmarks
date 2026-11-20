const MAX_TEXT_LENGTH: usize = 4096;
const MAX_PATTERN_LENGTH: usize = 128;
const MAX_PARSEABLE_LENGTH: usize = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH + 1;
const PATTERN_SENTINEL: u8 = 4;

fn build_kmp_next(pattern: &[u8], length: usize, next: &mut [i64; MAX_PATTERN_LENGTH + 1]) {
    let mut i = 0_usize;
    let mut j = -1_i64;
    next[0] = -1;
    while i < length {
        while j > -1 && pattern[i] != pattern[j as usize] {
            j = next[j as usize];
        }
        i += 1;
        j += 1;
        let following = if i < length { pattern[i] } else { PATTERN_SENTINEL };
        if following == pattern[j as usize] {
            next[i] = next[j as usize];
        } else {
            next[i] = j;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn apostolico_crochemore_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let text_length_value = *input;
    let pattern_length_value = *input.add(1);
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length_value) ||
        !(1..=MAX_PATTERN_LENGTH as i64).contains(&pattern_length_value)
    {
        return -1;
    }
    let text_length = text_length_value as usize;
    let pattern_length = pattern_length_value as usize;
    if length != 2 + text_length + pattern_length { return -1; }

    let mut text = [0_u8; MAX_TEXT_LENGTH];
    let mut pattern = [0_u8; MAX_PATTERN_LENGTH];
    for index in 0..text_length {
        let value = *input.add(2 + index);
        if !(0..=3).contains(&value) { return -1; }
        text[index] = value as u8;
    }
    let pattern_offset = 2 + text_length;
    for index in 0..pattern_length {
        let value = *input.add(pattern_offset + index);
        if !(0..=3).contains(&value) { return -1; }
        pattern[index] = value as u8;
    }

    let mut kmp_next = [0_i64; MAX_PATTERN_LENGTH + 1];
    build_kmp_next(&pattern, pattern_length, &mut kmp_next);

    let mut ell = 1_usize;
    while ell < pattern_length && pattern[ell - 1] == pattern[ell] {
        ell += 1;
    }
    if ell == pattern_length { ell = 0; }

    let mut match_count = 0_i64;
    let mut sum_offsets = 0_i64;
    let mut xor_offsets = 0_i64;
    if text_length >= pattern_length {
        let mut i = ell;
        let mut j = 0_usize;
        let mut k = 0_usize;
        while j <= text_length - pattern_length {
            while i < pattern_length && pattern[i] == text[j + i] {
                i += 1;
            }
            if i >= pattern_length {
                while k < ell && pattern[k] == text[j + k] {
                    k += 1;
                }
                if k >= ell {
                    match_count += 1;
                    sum_offsets += j as i64;
                    xor_offsets ^= j as i64;
                }
            }

            j += (i as i64 - kmp_next[i]) as usize;
            if i == ell {
                k = k.saturating_sub(1);
            } else if kmp_next[i] <= ell as i64 {
                k = if kmp_next[i] > 0 { kmp_next[i] as usize } else { 0 };
                i = ell;
            } else {
                k = ell;
                i = kmp_next[i] as usize;
            }
        }
    }

    (match_count << 36) | (sum_offsets << 12) | xor_offsets
}
