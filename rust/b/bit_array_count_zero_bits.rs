#[no_mangle]
pub extern "C" fn bit_array_count_zero_bits(values: *const i64, length: usize) -> i64 {
    if length > 4096 { return -1; }
    if length == 0 { return 0; }
    if values.is_null() { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut zero_count = 0_i64;
    for &value in values {
        if value != 0 && value != 1 { return -1; }
        if value == 0 { zero_count += 1; }
    }
    zero_count
}
