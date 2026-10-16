const MAX_TEXT_LENGTH: i64 = 4096;
const MAX_PATTERN_LENGTH: i64 = 31;

#[no_mangle]
pub unsafe extern "C" fn bitap_exact_match_31(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 { return -2; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] > MAX_TEXT_LENGTH || input[1] < 0 || input[1] > MAX_PATTERN_LENGTH { return -2; }
    let text_length = input[0] as usize;
    let pattern_length = input[1] as usize;
    if length != 2 + text_length + pattern_length || input[2..].iter().any(|v| *v < 97 || *v > 122) { return -2; }
    if pattern_length == 0 { return 0; }
    if pattern_length > text_length { return -1; }
    let mut masks = [u32::MAX; 26];
    for i in 0..pattern_length { masks[(input[2 + text_length + i] - 97) as usize] &= !(1u32 << i); }
    let mut state = !1u32;
    for i in 0..text_length {
        state |= masks[(input[2 + i] - 97) as usize];
        state <<= 1;
        if state & (1u32 << pattern_length) == 0 { return i as i64 - pattern_length as i64 + 1; }
    }
    -1
}
