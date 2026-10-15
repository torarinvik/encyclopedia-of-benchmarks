#[no_mangle]
pub extern "C" fn count_char(values: *const i64, length: usize) -> i64 {
    if length > 4096 || (length != 0 && values.is_null()) { return -1; }
    let input: &[i64] = if length == 0 { &[] } else {
        // The caller provides a valid array whenever length is nonzero.
        unsafe { std::slice::from_raw_parts(values, length) }
    };
    let mut count = 0i64;
    for &code in input {
        if !(0..=127).contains(&code) { return -1; }
        if !matches!(code, 9 | 10 | 11 | 12 | 13 | 32) { count += 1; }
    }
    count
}
