/// Linear merge over two packed ascending i32 sequences.
const MAX_TOTAL_LENGTH: usize = 1024;

#[no_mangle]
pub extern "C" fn merge_two_sorted_lists(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_TOTAL_LENGTH + 2 { return -1; }
    let first_count_value = unsafe { *input };
    let second_count_value = unsafe { *input.add(1) };
    if first_count_value < 0 || first_count_value > MAX_TOTAL_LENGTH as i64 ||
        second_count_value < 0 || second_count_value > MAX_TOTAL_LENGTH as i64 { return -1; }
    let first_count = first_count_value as usize;
    let second_count = second_count_value as usize;
    if first_count + second_count > MAX_TOTAL_LENGTH ||
        length != first_count + second_count + 2 { return -1; }
    for index in 0..first_count {
        let value = unsafe { *input.add(index + 2) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 ||
            (index != 0 && unsafe { *input.add(index + 1) } > value) { return -1; }
    }
    let second_start = first_count + 2;
    for index in 0..second_count {
        let value = unsafe { *input.add(second_start + index) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 ||
            (index != 0 && unsafe { *input.add(second_start + index - 1) } > value) { return -1; }
    }

    let total_count = first_count + second_count;
    let output_bytes = total_count * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    let mut first_index = 0;
    let mut second_index = 0;
    for written in 0..total_count {
        let value = if first_index == first_count {
            let value = unsafe { *input.add(second_start + second_index) };
            second_index += 1;
            value
        } else if second_index == second_count {
            let value = unsafe { *input.add(first_index + 2) };
            first_index += 1;
            value
        } else if unsafe { *input.add(first_index + 2) <= *input.add(second_start + second_index) } {
            let value = unsafe { *input.add(first_index + 2) };
            first_index += 1;
            value
        } else {
            let value = unsafe { *input.add(second_start + second_index) };
            second_index += 1;
            value
        };
        let bits = value as i32 as u32;
        for byte in 0..4 {
            unsafe { *output.add(written * 4 + byte) = (bits >> (byte * 8)) as u8; }
        }
    }
    total_count as i64
}
