const MAX_LENGTH: usize = 256;

fn write_i32_le(output: &mut [u8], index: usize, value: i32) {
    let offset = index * 4;
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn reverse_singly_linked_list(
    values: *const i32,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length > MAX_LENGTH { return -1; }
    let output_bytes = length * 4;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let input = std::slice::from_raw_parts(values, length);
    let result = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..length {
        write_i32_le(result, index, input[length - 1 - index]);
    }
    output_bytes as i64
}
