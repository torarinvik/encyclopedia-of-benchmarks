const MAX_LIST_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_VALUE: i64 = 2_147_483_647;

#[no_mangle]
pub unsafe extern "C" fn sublist_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let main_count_value = input[0];
    let pattern_count_value = input[1];
    if !(0..=MAX_LIST_LENGTH as i64).contains(&main_count_value) ||
        !(0..=MAX_LIST_LENGTH as i64).contains(&pattern_count_value) { return -1; }
    let main_count = main_count_value as usize;
    let pattern_count = pattern_count_value as usize;
    if length != 2 + main_count + pattern_count { return -1; }
    if input[2..].iter().any(|&value| !(0..=MAX_VALUE).contains(&value)) { return -1; }

    if main_count == 0 || pattern_count == 0 || pattern_count > main_count { return 0; }
    let pattern_offset = 2 + main_count;
    for start in 0..=main_count - pattern_count {
        let mut matched = 0;
        while matched < pattern_count && input[2 + start + matched] == input[pattern_offset + matched] {
            matched += 1;
        }
        if matched == pattern_count { return 1; }
    }
    0
}
