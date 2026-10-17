const MAX_INPUT_LENGTH: usize = 258;
const MAX_LIST_LENGTH: usize = 256;

fn write_i32_le(output: &mut [u8], index: usize, value: i32) {
    let offset = index * 4;
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn reverse_kgroup(
    input: *const i32,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let group_size_value = values[0];
    let list_length = length - 1;
    if group_size_value < 1 || group_size_value as usize > MAX_LIST_LENGTH || list_length > MAX_LIST_LENGTH { return -1; }
    let group_size = group_size_value as usize;
    let output_bytes = list_length * 4;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let result = std::slice::from_raw_parts_mut(output, output_bytes);
    let mut start = 0;
    while start + group_size <= list_length {
        for offset in 0..group_size {
            write_i32_le(result, start + offset, values[1 + start + group_size - 1 - offset]);
        }
        start += group_size;
    }
    while start < list_length {
        write_i32_le(result, start, values[1 + start]);
        start += 1;
    }
    output_bytes as i64
}
