#[no_mangle]
pub unsafe extern "C" fn upper(raw: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if length > 256 || (length != 0 && raw.is_null()) { return -1; }
    let input = if length == 0 { &[] } else { std::slice::from_raw_parts(raw, length) };
    if input.iter().any(|value| *value < 0 || *value > 127 || matches!(*value, 9..=13 | 32)) { return -1; }
    if capacity < length || (length != 0 && output.is_null()) { return -2; }
    if length == 0 { return 0; }
    let result = std::slice::from_raw_parts_mut(output, length);
    for (dst, src) in result.iter_mut().zip(input.iter()) { *dst = *src as u8; }
    for byte in result.iter_mut() { if (b'a'..=b'z').contains(byte) { *byte -= 32; } }
    length as i64
}
