/// Return whether a pattern occurs using Knuth-Morris-Pratt matching.
#[no_mangle]
pub extern "C" fn knuth_morris_pratt_contains(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 2 || length > 8194 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(packed, length) };
    if values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 4096 { return -1; }
    let text_length = values[0] as usize;
    let pattern_length = values[1] as usize;
    if length != 2 + text_length + pattern_length { return -1; }
    if values[2..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    if pattern_length == 0 { return 0; }

    let pattern_start = 2 + text_length;
    let mut prefix = [0usize; 4096];
    let mut matched = 0usize;
    for index in 1..pattern_length {
        while matched > 0 && values[pattern_start + index] != values[pattern_start + matched] {
            matched = prefix[matched - 1];
        }
        if values[pattern_start + index] == values[pattern_start + matched] { matched += 1; }
        prefix[index] = matched;
    }

    matched = 0;
    for index in 0..text_length {
        while matched > 0 && values[2 + index] != values[pattern_start + matched] {
            matched = prefix[matched - 1];
        }
        if values[2 + index] == values[pattern_start + matched] { matched += 1; }
        if matched == pattern_length { return 1; }
    }
    0
}
