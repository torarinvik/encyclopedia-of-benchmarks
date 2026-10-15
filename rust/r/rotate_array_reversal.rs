/// Rotate by reversing the whole array, then each side of the rotation.
const MAX_ARRAY_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = MAX_ARRAY_LENGTH + 1;

fn reverse_range(values: &mut [i32; MAX_ARRAY_LENGTH], start_value: usize, end_value: usize) {
    let mut start = start_value;
    let mut ending = end_value;
    while start < ending {
        ending -= 1;
        if start >= ending { break; }
        values.swap(start, ending);
        start += 1;
    }
}

#[no_mangle]
pub extern "C" fn rotate_array_reversal(input: *const i64, length: usize,
                                          output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let steps = unsafe { *input };
    if steps < i32::MIN as i64 || steps > i32::MAX as i64 { return -1; }
    let count = length - 1;
    let mut values = [0_i32; MAX_ARRAY_LENGTH];
    for index in 0..count {
        let value = unsafe { *input.add(index + 1) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value as i32;
    }
    let output_bytes = count * 4;
    if output_capacity < output_bytes { return -2; }
    let shift = if count == 0 { 0 } else { steps.rem_euclid(count as i64) as usize };
    reverse_range(&mut values, 0, count);
    reverse_range(&mut values, 0, shift);
    reverse_range(&mut values, shift, count);
    for index in 0..count {
        let bytes = values[index].to_le_bytes();
        for byte in 0..4 { unsafe { *output.add(index * 4 + byte) = bytes[byte]; } }
    }
    count as i64
}
