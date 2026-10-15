/// Rotate an array right by repeating a one-place shift.
const MAX_ARRAY_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = MAX_ARRAY_LENGTH + 1;
const MAX_ROTATIONS: i64 = 1024;

#[no_mangle]
pub extern "C" fn rotate_array(input: *const i64, length: usize,
                               output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let rotations = unsafe { *input };
    if rotations < 0 || rotations > MAX_ROTATIONS { return -1; }
    let count = length - 1;
    let mut values = [0_i32; MAX_ARRAY_LENGTH];
    for index in 0..count {
        let value = unsafe { *input.add(index + 1) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value as i32;
    }
    let output_bytes = count * 4;
    if output_capacity < output_bytes { return -2; }
    for _ in 0..rotations {
        if count > 1 {
            let last = values[count - 1];
            for index in (1..count).rev() { values[index] = values[index - 1]; }
            values[0] = last;
        }
    }
    for index in 0..count {
        let bytes = values[index].to_le_bytes();
        for byte in 0..4 { unsafe { *output.add(index * 4 + byte) = bytes[byte]; } }
    }
    count as i64
}
