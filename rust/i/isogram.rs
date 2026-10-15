/// Check whether ASCII letters form an isogram, ignoring case and spaces.
#[no_mangle]
pub extern "C" fn isogram(values: *const i64, length: usize) -> i64 {
    if length > 4096 || (length != 0 && values.is_null()) { return -1; }
    if length == 0 { return 1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut seen = [false; 26];
    for &value in values {
        if value == 32 { continue; }
        let lower = if (65..=90).contains(&value) { value + 32 } else { value };
        if !(97..=122).contains(&lower) { return -1; }
        let letter = (lower - 97) as usize;
        if seen[letter] { return 0; }
        seen[letter] = true;
    }
    1
}
