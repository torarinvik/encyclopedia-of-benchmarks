/// Square a sorted array and emit the results in ascending order.
const MAX_ARRAY_LENGTH: usize = 10000;

#[no_mangle]
pub extern "C" fn squares_of_a_sorted_array(input: *const i64, length: usize,
                                            output: *mut u8,
                                            output_capacity: usize) -> i64 {
    if length > MAX_ARRAY_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = unsafe { *input.add(index) };
        if !(-10000..=10000).contains(&value) { return -1; }
        if index != 0 && unsafe { *input.add(index - 1) } > value { return -1; }
    }
    let output_bytes = length * 8;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }

    let mut left = 0;
    let mut right = length;
    let mut destination = length;
    while destination > 0 {
        destination -= 1;
        let left_value = unsafe { *input.add(left) };
        let right_value = unsafe { *input.add(right - 1) };
        let left_magnitude = if left_value < 0 { -left_value } else { left_value };
        let right_magnitude = if right_value < 0 { -right_value } else { right_value };
        let value;
        if left_magnitude > right_magnitude {
            value = left_value;
            left += 1;
        } else {
            value = right_value;
            right -= 1;
        }
        let bytes = ((value * value) as u64).to_le_bytes();
        for byte in 0..8 {
            unsafe { *output.add(destination * 8 + byte) = bytes[byte]; }
        }
    }
    length as i64
}
