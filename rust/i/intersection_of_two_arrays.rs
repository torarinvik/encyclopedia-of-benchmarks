const MAX_ARRAY_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 * (MAX_ARRAY_LENGTH + 1);
const BYTES_PER_VALUE: usize = 4;

#[no_mangle]
pub unsafe extern "C" fn intersection_of_two_arrays(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    let first_length_value = packed[0];
    if !(0..=MAX_ARRAY_LENGTH as i64).contains(&first_length_value) { return -1; }
    let first_length = first_length_value as usize;
    let second_length_position = 1 + first_length;
    if second_length_position >= length { return -1; }
    let second_length_value = packed[second_length_position];
    if !(0..=MAX_ARRAY_LENGTH as i64).contains(&second_length_value) { return -1; }
    let second_length = second_length_value as usize;
    let second_start = second_length_position + 1;
    if second_start + second_length != length { return -1; }

    let first = &packed[1..second_length_position];
    let second = &packed[second_start..];
    if first.iter().chain(second.iter()).any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64)
        || first.windows(2).any(|pair| pair[0] > pair[1])
        || second.windows(2).any(|pair| pair[0] > pair[1]) { return -1; }

    let maximum_result = first_length.min(second_length);
    if output_capacity < maximum_result * BYTES_PER_VALUE || (maximum_result > 0 && output.is_null()) { return -2; }
    let mut first_index = 0usize;
    let mut second_index = 0usize;
    let mut result_count = 0usize;
    let mut previous_value = 0i64;
    while first_index < first_length && second_index < second_length {
        let left = first[first_index];
        let right = second[second_index];
        if left < right {
            first_index += 1;
        } else if left > right {
            second_index += 1;
        } else {
            if result_count == 0 || left != previous_value {
                let encoded = (left as i32).to_le_bytes();
                std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(result_count * BYTES_PER_VALUE), BYTES_PER_VALUE);
                previous_value = left;
                result_count += 1;
            }
            first_index += 1;
            second_index += 1;
        }
    }
    result_count as i64
}
