const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn is_lower(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -1; }
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(32..=126).contains(&value) { return -1; }
        if (65..=90).contains(&value) { return 0; }
    }
    1
}
