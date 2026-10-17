#[no_mangle]
pub unsafe extern "C" fn long_utils(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=3).contains(&values[0]) || !(0..=63).contains(&values[2]) { return -1; }
    if output.is_null() || capacity < 8 { return -2; }
    let bits = values[1] as u64;
    let distance = values[2] as u32;
    let rotated = match values[0] {
        0 | 1 => bits.rotate_left(distance),
        _ => bits.rotate_right(distance),
    };
    for byte in 0..8 { *output.add(byte) = (rotated >> (8 * byte)) as u8; }
    8
}
