/// Emit Java-style swap-recursion permutations, retaining duplicate rows.
const MAX_LENGTH: usize = 6;
const MAX_PARSEABLE_LENGTH: usize = 8;

unsafe fn store_i32_le(output: *mut u8, position: usize, value: i32) {
    for (byte, octet) in value.to_le_bytes().iter().enumerate() {
        unsafe { *output.add(position + byte) = *octet; }
    }
}

unsafe fn generate(values: &mut [i32; MAX_LENGTH], n: usize, index: usize,
    output: *mut u8, result_count: &mut usize) {
    if index == n {
        let row_start = *result_count * n * 4;
        for column in 0..n {
            unsafe { store_i32_le(output, row_start + column * 4, values[column]); }
        }
        *result_count += 1;
        return;
    }
    for position in index..n {
        values.swap(index, position);
        unsafe { generate(values, n, index + 1, output, result_count); }
        values.swap(index, position);
    }
}

#[no_mangle]
pub unsafe extern "C" fn permutation_array(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH { return -1; }
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
    let mut permutation_count = 1usize;
    for factor in 2..=n { permutation_count *= factor; }
    let required = permutation_count * n * 4;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    let mut result_count = 0usize;
    unsafe { generate(&mut values, n, 0, output, &mut result_count); }
    result_count as i64
}
