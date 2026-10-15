#[no_mangle]
pub unsafe extern "C" fn alternative_list_arrange(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let data = std::slice::from_raw_parts(input, length);
    if !(0..=64).contains(&data[0]) { return -1; }
    let a = data[0] as usize;
    if 1 + a >= length || !(0..=64).contains(&data[1 + a]) { return -1; }
    let b = data[1 + a] as usize;
    if length != 2 + a + b { return -1; }
    let count = a + b;
    if count == 0 { return 0; }
    if capacity < count * 8 || (count != 0 && output.is_null()) { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, count * 8);
    let mut out = 0;
    for i in 0..a.max(b) {
        if i < a { bytes[out..out + 8].copy_from_slice(&data[1 + i].to_le_bytes()); out += 8; }
        if i < b { bytes[out..out + 8].copy_from_slice(&data[2 + a + i].to_le_bytes()); out += 8; }
    }
    count as i64
}
