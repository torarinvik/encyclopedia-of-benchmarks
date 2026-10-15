/// Emit permutations in depth-first input-index order; equal values keep multiplicity.
const MAX_LENGTH: usize = 6;
const BYTES_PER_VALUE: usize = 4;

unsafe fn store_i32_le(output: *mut u8, position: usize, value: i32) {
    for (byte, octet) in value.to_le_bytes().iter().enumerate() {
        *output.add(position + byte) = *octet;
    }
}

unsafe fn generate(values: &[i32; MAX_LENGTH], n: usize, depth: usize,
    current: &mut [i32; MAX_LENGTH], used: &mut [bool; MAX_LENGTH],
    output: *mut u8, result_count: &mut usize) {
    if depth == n {
        let row_start = *result_count * n * BYTES_PER_VALUE;
        for index in 0..n {
            store_i32_le(output, row_start + index * BYTES_PER_VALUE, current[index]);
        }
        *result_count += 1;
        return;
    }
    for index in 0..n {
        if used[index] { continue; }
        current[depth] = values[index];
        used[index] = true;
        generate(values, n, depth + 1, current, used, output, result_count);
        used[index] = false;
    }
}

#[no_mangle]
pub extern "C" fn all_permutations(input: *const i64, length: usize,
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
    let mut permutation_count = 1usize;
    for factor in 2..=n { permutation_count *= factor; }
    let required = permutation_count * n * BYTES_PER_VALUE;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    let mut current = [0i32; MAX_LENGTH];
    let mut used = [false; MAX_LENGTH];
    let mut result_count = 0usize;
    unsafe { generate(&values, n, 0, &mut current, &mut used, output, &mut result_count); }
    result_count as i64
}
