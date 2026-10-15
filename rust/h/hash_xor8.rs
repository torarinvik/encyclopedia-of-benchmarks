#[no_mangle]
pub extern "C" fn hash_xor8(values: *const i64, length: usize) -> i64 {
    if length > 100_001 || (values.is_null() && length != 0) { return -1; }
    if length == 0 { return 0; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    for &value in values {
        if value == 0 { break; }
        if !(0..=127).contains(&value) { return -1; }
    }
    let mut hash = 0u32;
    for &value in values {
        if value == 0 { break; }
        hash = (hash + value as u32) & 0xff;
    }
    (((hash ^ 0xff) + 1) & 0xff) as i64
}
