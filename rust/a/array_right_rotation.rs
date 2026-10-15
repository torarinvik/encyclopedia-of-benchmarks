/// Return a fresh right rotation; shifts at least as large as the array length yield empty output.
const MAX_ARRAY_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = MAX_ARRAY_LENGTH + 1;
const MAX_SHIFT: i64 = 1024;

fn write_i32_le(output: *mut u8, index: usize, value: i32) {
    let bytes = value.to_le_bytes();
    for byte in 0..4 {
        unsafe { *output.add(index * 4 + byte) = bytes[byte]; }
    }
}

#[no_mangle]
pub extern "C" fn array_right_rotation(input: *const i64, length: usize,
                                       output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let shift_value = unsafe { *input };
    if shift_value < 0 || shift_value > MAX_SHIFT { return -1; }
    let count = length - 1;
    let mut values = [0_i32; MAX_ARRAY_LENGTH];
    for index in 0..count {
        let value = unsafe { *input.add(index + 1) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value as i32;
    }
    let shift = shift_value as usize;
    if shift >= count { return 0; }
    let output_bytes = count * 4;
    if output_capacity < output_bytes || output.is_null() { return -2; }
    for index in 0..shift {
        write_i32_le(output, index, values[count - shift + index]);
    }
    for index in shift..count {
        write_i32_le(output, index, values[index - shift]);
    }
    count as i64
}
