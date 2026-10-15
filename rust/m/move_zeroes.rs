/// Stable nonzero compaction followed by a zero-fill pass.
const MAX_LENGTH: usize = 4096;

unsafe fn write_i32_le(output: *mut u8, index: usize, value: i64) {
    let bits = value as i32 as u32;
    for byte in 0..4 { *output.add(index * 4 + byte) = (bits >> (byte * 8)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn move_zeroes(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
    }
    let output_bytes = length * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    let mut write_index = 0;
    for index in 0..length {
        let value = *input.add(index);
        if value != 0 { write_i32_le(output, write_index, value); write_index += 1; }
    }
    while write_index < length { write_i32_le(output, write_index, 0); write_index += 1; }
    length as i64
}
