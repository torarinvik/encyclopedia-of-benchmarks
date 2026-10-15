/// Return whether every bounded ASCII character value equals the first.
#[no_mangle]
pub extern "C" fn characters_same(values: *const i64, length: usize) -> i64 {
    if length > 256 || (length != 0 && values.is_null()) { return -1; }
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(0..=127).contains(&value) { return -1; }
    }
    if length == 0 { return 1; }
    let first = unsafe { *values };
    for index in 1..length {
        if unsafe { *values.add(index) } != first { return 0; }
    }
    1
}
