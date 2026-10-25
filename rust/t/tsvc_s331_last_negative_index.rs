#[no_mangle]
pub extern "C" fn tsvc_s331_last_negative_index(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 257 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > 256 || length != 1 + values[0] as usize { return -1; }
    let mut result = 0i64;
    for index in 0..values[0] as usize {
        let value = values[1 + index];
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
        if value < 0 { result = index as i64 + 1; }
    }
    result
}
