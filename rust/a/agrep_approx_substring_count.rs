const MAX_PATTERN_LENGTH: i64 = 63;
const MAX_TEXT_LENGTH: i64 = 4096;
const MAX_ERRORS: i64 = 2;

#[no_mangle]
pub unsafe extern "C" fn agrep_approx_substring_count(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 { return -2; }
    let input = std::slice::from_raw_parts(values, length);
    if !(1..=MAX_PATTERN_LENGTH).contains(&input[0]) ||
        !(0..=MAX_TEXT_LENGTH).contains(&input[1]) || !(0..=MAX_ERRORS).contains(&input[2]) {
        return -2;
    }
    let pattern_length = input[0] as usize;
    let text_length = input[1] as usize;
    if length != 3 + pattern_length + text_length ||
        input[3..].iter().any(|byte| !(32i64..=126i64).contains(byte)) {
        return -2;
    }

    let mut previous = [0i64; 64];
    let mut current = [0i64; 64];
    for j in 0..=pattern_length { previous[j] = j as i64; }
    let mut matches = 0i64;
    let text_offset = 3 + pattern_length;
    for i in 0..text_length {
        current[0] = 0;
        for j in 1..=pattern_length {
            let substitution = previous[j - 1] +
                if input[3 + j - 1] == input[text_offset + i] { 0 } else { 1 };
            current[j] = (previous[j] + 1).min((current[j - 1] + 1).min(substitution));
        }
        if current[pattern_length] <= input[2] { matches += 1; }
        previous[..=pattern_length].copy_from_slice(&current[..=pattern_length]);
    }
    matches
}
