#[no_mangle]
pub unsafe extern "C" fn reverse_string(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let data = std::slice::from_raw_parts(input, length);
    if !(0..=256).contains(&data[0]) || length != data[0] as usize + 1 { return -1; }
    let n = data[0] as usize;
    for i in 0..n {
        if !(33..=126).contains(&data[i + 1]) { return -1; }
    }
    if output.is_null() || capacity < n + 1 { return -2; }
    let result = std::slice::from_raw_parts_mut(output, capacity);
    for i in 0..n {
        result[i] = data[n - i] as u8;
    }
    result[n] = 0;
    n as i64
}
