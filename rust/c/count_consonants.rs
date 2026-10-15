const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn count_consonants(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > MAX_LENGTH || values.is_null() { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if length == 1 && input[0] == 48 { return -1; }
    let mut count = 0i64;
    for &code in input {
        if !(32..=126).contains(&code) { return -1; }
        let lower = if (65..=90).contains(&code) { code + 32 } else { code };
        if (97..=122).contains(&lower) && ![97, 101, 105, 111, 117].contains(&lower) { count += 1; }
    }
    count
}
