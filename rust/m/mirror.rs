const MAX_LENGTH: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_LENGTH + 1;

#[no_mangle]
pub unsafe extern "C" fn mirror(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = core::slice::from_raw_parts(input, length);
    if !(0..=MAX_LENGTH as i64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1..].iter().any(|&byte| !(1..=127).contains(&byte)) { return -1; }
    if output.is_null() || capacity < n + 1 { return -2; }
    let mut buffer = [0u8; MAX_INPUT_LENGTH];
    for i in 0..n { buffer[i] = values[i + 1] as u8; }
    buffer[n] = 0;
    let mut logical_length = 0;
    while buffer[logical_length] != 0 { logical_length += 1; }
    if logical_length > 0 {
        let mut left = 0;
        let mut right = logical_length - 1;
        while left <= right {
            buffer.swap(left, right);
            left += 1;
            if right == 0 { break; }
            right -= 1;
        }
    }
    let result = core::slice::from_raw_parts_mut(output, capacity);
    result[..n].copy_from_slice(&buffer[..n]);
    result[n] = 0;
    n as i64
}
