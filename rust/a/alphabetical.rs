/// Check whether an ASCII letter string is case-insensitively sorted.
fn is_ascii_letter(value: i64) -> bool {
    (i64::from(b'A')..=i64::from(b'Z')).contains(&value)
        || (i64::from(b'a')..=i64::from(b'z')).contains(&value)
}

fn lowercase_ascii(value: i64) -> i64 {
    if (i64::from(b'A')..=i64::from(b'Z')).contains(&value) { value + 32 } else { value }
}

#[no_mangle]
pub extern "C" fn alphabetical(values: *const i64, length: usize) -> i64 {
    if length > 256 || (length != 0 && values.is_null()) { return -1; }
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(0..=127).contains(&value) { return -1; }
    }
    if length == 0 { return 0; }
    let mut previous = -1i64;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !is_ascii_letter(value) { return 0; }
        let current = lowercase_ascii(value);
        if current < previous { return 0; }
        previous = current;
    }
    1
}
