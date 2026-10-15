#[no_mangle]
pub unsafe extern "C" fn binary_xor_operator(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|value| *value < 0 || *value > i32::MAX as i64) { return -1; }
    let a = values[0] as u64;
    let b = values[1] as u64;
    let largest = a.max(b);
    let width = (64 - largest.leading_zeros() as usize).max(1);
    let output_length = width + 2;
    if capacity < output_length || output.is_null() { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, output_length);
    bytes[0] = b'0'; bytes[1] = b'b';
    let result = a ^ b;
    for i in 0..width {
        let bit = width - 1 - i;
        bytes[2 + i] = if (result >> bit) & 1 == 1 { b'1' } else { b'0' };
    }
    output_length as i64
}
