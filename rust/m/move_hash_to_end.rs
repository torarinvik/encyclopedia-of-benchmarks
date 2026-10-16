#[no_mangle]
pub unsafe extern "C" fn move_hash_to_end(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > 258 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let text_length = input[0];
    if !(0..=256).contains(&text_length) || length != text_length as usize + 1 { return -1; }
    let text = &input[1..];
    if text.iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    let n = text_length as usize;
    if capacity < n || (n > 0 && output.is_null()) { return -2; }
    if n == 0 { return 0; }
    let out = std::slice::from_raw_parts_mut(output, n);
    let mut position = 0;
    for &byte in text {
        if byte != 35 { out[position] = byte as u8; position += 1; }
    }
    while position < n { out[position] = b'#'; position += 1; }
    n as i64
}
