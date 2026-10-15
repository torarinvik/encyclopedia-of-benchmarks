#[no_mangle]
pub extern "C" fn validate_subsequence(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 8194 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input[0] < 0 || input[0] > 4096 || input[1] < 0 || input[1] > 4096 { return -1; }
    let array_length = input[0] as usize;
    let sequence_length = input[1] as usize;
    if length != 2 + array_length + sequence_length { return -1; }
    if input[2..].iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) { return -1; }

    if array_length == 0 { return 0; }
    if sequence_length == 0 { return 1; }
    let sequence_start = 2 + array_length;
    let mut array_index = 0;
    let mut sequence_index = 0;
    while sequence_index < sequence_length && array_index < array_length {
        if input[sequence_start + sequence_index] == input[2 + array_index] { sequence_index += 1; }
        array_index += 1;
    }
    if sequence_index == sequence_length { 1 } else { 0 }
}
