/// Emit subsequences in skip-before-include depth-first order.
const MAX_LENGTH: usize = 8;
const BYTES_PER_VALUE: usize = 4;

unsafe fn store_u32_le(output: *mut u8, position: usize, value: u32) {
    for (byte, octet) in value.to_le_bytes().iter().enumerate() {
        *output.add(position + byte) = *octet;
    }
}

unsafe fn store_i32_le(output: *mut u8, position: usize, value: i32) {
    store_u32_le(output, position, value as u32);
}

unsafe fn generate(values: &[i32; MAX_LENGTH], n: usize, index: usize,
    current: &mut [i32; MAX_LENGTH], current_length: usize,
    output: *mut u8, output_cursor: &mut usize, result_count: &mut usize) {
    if index == n {
        store_u32_le(output, *output_cursor, current_length as u32);
        *output_cursor += BYTES_PER_VALUE;
        for item in 0..current_length {
            store_i32_le(output, *output_cursor, current[item]);
            *output_cursor += BYTES_PER_VALUE;
        }
        *result_count += 1;
        return;
    }
    generate(values, n, index + 1, current, current_length, output, output_cursor, result_count);
    current[current_length] = values[index];
    generate(values, n, index + 1, current, current_length + 1, output, output_cursor, result_count);
}

#[no_mangle]
pub extern "C" fn all_subsequences(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_LENGTH + 1 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = packed[0];
    if n_value < 0 || n_value > MAX_LENGTH as i64 || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    let mut values = [0i32; MAX_LENGTH];
    for index in 0..n {
        let value = packed[index + 1];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value as i32;
    }
    let mut result_count = 1usize;
    for _ in 0..n { result_count *= 2; }
    let value_count = if n == 0 { 0 } else { n * (result_count / 2) };
    let required = (result_count + value_count) * BYTES_PER_VALUE;
    if output_capacity < required || output.is_null() { return -2; }
    let mut current = [0i32; MAX_LENGTH];
    let mut output_cursor = 0usize;
    let mut emitted = 0usize;
    unsafe { generate(&values, n, 0, &mut current, 0, output, &mut output_cursor, &mut emitted); }
    emitted as i64
}
