/// Return the first pattern occurrence using a direct character-by-character scan.
const MAX_STRING_LENGTH: usize = 1024;

#[no_mangle]
pub extern "C" fn str_str_brute_force(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 2 || length > 2 + 2 * MAX_STRING_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(packed, length) };
    if values[0] < 0 || values[0] > MAX_STRING_LENGTH as i64 ||
        values[1] < 0 || values[1] > MAX_STRING_LENGTH as i64 { return -1; }
    let text_length = values[0] as usize;
    let pattern_length = values[1] as usize;
    if length != 2 + text_length + pattern_length { return -1; }
    if values[2..].iter().any(|&value| !(1..=127).contains(&value)) { return -1; }
    if pattern_length == 0 { return 0; }
    if pattern_length > text_length { return -1; }

    let pattern_start = 2 + text_length;
    for start in 0..=text_length - pattern_length {
        let mut offset = 0;
        while offset < pattern_length && values[2 + start + offset] == values[pattern_start + offset] {
            offset += 1;
        }
        if offset == pattern_length { return start as i64; }
    }
    -1
}
