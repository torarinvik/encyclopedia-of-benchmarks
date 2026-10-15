/// Return the longest printable-ASCII substring with no repeated byte.
const MAX_LENGTH: usize = 1024;
const ALPHABET_SIZE: usize = 95;

#[no_mangle]
pub extern "C" fn longest_substring_without_repeating_characters(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -2; }
    let mut last_seen = [-1i64; ALPHABET_SIZE];
    let mut window_start = 0usize;
    let mut longest = 0usize;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(32..=126).contains(&value) { return -2; }
        let slot = (value - 32) as usize;
        let previous = last_seen[slot];
        if previous >= 0 && previous as usize >= window_start { window_start = previous as usize + 1; }
        last_seen[slot] = index as i64;
        let current = index - window_start + 1;
        if current > longest { longest = current; }
    }
    longest as i64
}
