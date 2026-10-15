/// Emit the reflected n-bit Gray-code sequence as little-endian u32 values.
#[no_mangle]
pub extern "C" fn gray_code(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 1 { return -1; }
    let bit_count = unsafe { *input };
    if !(0..=13).contains(&bit_count) { return -1; }
    let count = if bit_count == 0 { 0usize } else { 1usize << bit_count as u32 };
    let required = count * 4;
    if output.is_null() || output_capacity < required { return -2; }
    for index in 0..count {
        let gray = index ^ (index >> 1);
        for byte in 0..4 {
            unsafe { output.add(4 * index + byte).write((gray >> (8 * byte)) as u8); }
        }
    }
    count as i64
}
