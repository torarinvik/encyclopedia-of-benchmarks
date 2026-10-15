const MAX_LENGTH: usize = 4096;

fn is_trim_character(value: i64) -> bool { value <= 32 }
fn is_regex_whitespace(value: i64) -> bool { matches!(value, 9 | 10 | 11 | 12 | 13 | 32) }

/// Count tokens after Java String.trim() and split("\\s+").
#[no_mangle]
pub extern "C" fn count_words(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length > 0 && values.is_null()) {
        return -1;
    }
    let data = if length == 0 { &[] } else { unsafe { std::slice::from_raw_parts(values, length) } };
    if data.iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }
    if length == 0 {
        return 0;
    }
    let mut start = 0;
    let mut ending = length;
    while start < ending && is_trim_character(data[start]) { start += 1; }
    while ending > start && is_trim_character(data[ending - 1]) { ending -= 1; }
    if start == ending {
        return 1;
    }
    let mut count = 0_i64;
    let mut in_word = false;
    for &value in &data[start..ending] {
        if is_regex_whitespace(value) {
            in_word = false;
        } else if !in_word {
            count += 1;
            in_word = true;
        }
    }
    count
}
