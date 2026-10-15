const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn is_contains_unique_chars(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -1; }
    let input = if length == 0 { &[][..] } else { unsafe { std::slice::from_raw_parts(values, length) } };
    if input.iter().any(|&value| !(0..=127).contains(&value)) { return -1; }

    let mut seen = [0_u64; 2];
    for &value in input {
        let value = value as usize;
        let word = value / 64;
        let mask = 1_u64 << (value % 64);
        if seen[word] & mask != 0 { return 0; }
        seen[word] |= mask;
    }
    1
}
