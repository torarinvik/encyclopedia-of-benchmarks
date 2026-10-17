const MAX_INPUT_LENGTH: usize = 202;
const MAX_LIST_LENGTH: usize = 100;

fn write_i32_le(output: &mut [u8], index: usize, value: i32) {
    let offset = index * 4;
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn linkedlist_implentation_usingarray(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let operation_count = values[0];
    if !(0..=100).contains(&operation_count) || length != 1 + 2 * operation_count as usize { return -1; }
    let mut items = [0i32; MAX_LIST_LENGTH];
    let (mut item_count, mut cursor) = (0usize, 1usize);
    for _ in 0..operation_count {
        let opcode = values[cursor];
        let raw_value = values[cursor + 1];
        cursor += 2;
        if raw_value < i32::MIN as i64 || raw_value > i32::MAX as i64 || item_count >= MAX_LIST_LENGTH { return -1; }
        let value = raw_value as i32;
        if opcode == 0 {
            for index in (1..=item_count).rev() { items[index] = items[index - 1]; }
            items[0] = value;
            item_count += 1;
        } else if opcode == 1 {
            if item_count == 0 { return -1; }
            items[item_count] = value;
            item_count += 1;
        } else {
            return -1;
        }
    }

    let output_bytes = (item_count + 1) * 4;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let result = std::slice::from_raw_parts_mut(output, output_bytes);
    write_i32_le(result, 0, item_count as i32);
    for index in 0..item_count { write_i32_le(result, index + 1, items[index]); }
    output_bytes as i64
}
