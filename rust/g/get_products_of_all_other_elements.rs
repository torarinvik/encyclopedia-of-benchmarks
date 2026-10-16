const MAX_ARRAY_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;

fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = bytes[byte]; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn get_products_of_all_other_elements(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let n_value = *input;
    if n_value < 0 || n_value > MAX_ARRAY_LENGTH as i64 { return -1; }
    let n = n_value as usize;
    if length != n + 1 { return -1; }
    let mut result = [0i64; MAX_ARRAY_LENGTH];
    for i in 0..n {
        let value = *input.add(i + 1);
        if !(-2..=2).contains(&value) { return -1; }
    }
    if n < 2 { return 0; }
    let output_bytes = n * 8;
    if output.is_null() || capacity < output_bytes { return -2; }

    result[0] = 1;
    for i in 0..n - 1 { result[i + 1] = *input.add(i + 1) * result[i]; }
    let mut suffix = 1i64;
    for i in (1..n).rev() {
        let value = *input.add(i + 1);
        result[i - 1] *= suffix * value;
        suffix *= value;
    }
    for i in 0..n { write_i64_le(output, i * 8, result[i]); }
    output_bytes as i64
}
