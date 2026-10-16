const MAX_TEXT_LENGTH: i64 = 4096;
const MAX_PATTERN_LENGTH: i64 = 63;

#[no_mangle]
pub unsafe extern "C" fn bitap_string_match(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 {
        return -2;
    }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] > MAX_TEXT_LENGTH || input[1] < 0 || input[1] > MAX_PATTERN_LENGTH {
        return -2;
    }
    let text_length = input[0] as usize;
    let pattern_length = input[1] as usize;
    if length != 2 + text_length + pattern_length
        || input[2..].iter().any(|value| *value < 97 || *value > 122)
    {
        return -2;
    }
    if pattern_length == 0 {
        return 0;
    }
    if pattern_length > text_length {
        return -1;
    }

    let mut masks = [u64::MAX; 26];
    for index in 0..pattern_length {
        let letter = (input[2 + text_length + index] - 97) as usize;
        masks[letter] &= !(1_u64 << index);
    }
    let mut state = !1_u64;
    for index in 0..text_length {
        let letter = (input[2 + index] - 97) as usize;
        state |= masks[letter];
        state <<= 1;
        if state & (1_u64 << pattern_length) == 0 {
            return index as i64 - pattern_length as i64 + 1;
        }
    }
    -1
}
