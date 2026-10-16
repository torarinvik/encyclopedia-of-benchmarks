/// Go Problem17: sum byte lengths after splitting on ASCII space.
#[no_mangle]
pub extern "C" fn word_length_sum(values: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    if length == 0 { return 0; }
    if values.is_null() { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut total = 0_i64;
    for &value in values {
        if !(0..=255).contains(&value) { return -1; }
        if value != 32 { total += 1; }
    }
    total
}
