fn put_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn thomas_algorithm(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 32;
    if input.is_null() || length < 5 || length > 1 + 4 * MAX_N { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_N as i64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != 1 + 4 * n { return -1; }

    let lower = &values[1..1 + n];
    let diagonal = &values[1 + n..1 + 2 * n];
    let upper = &values[1 + 2 * n..1 + 3 * n];
    let rhs = &values[1 + 3 * n..1 + 4 * n];
    if lower[0] != 0 || upper[n - 1] != 0 { return -1; }
    for row in 0..n {
        if !(-16..=16).contains(&lower[row]) || !(-16..=16).contains(&upper[row])
            || !(17..=64).contains(&diagonal[row]) || !(-1000..=1000).contains(&rhs[row]) {
            return -1;
        }
        if diagonal[row] <= lower[row].abs() + upper[row].abs() { return -1; }
    }
    let output_bytes = n * 8;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut modified_upper = [0.0_f64; MAX_N];
    let mut modified_rhs = [0.0_f64; MAX_N];
    let mut solution = [0.0_f64; MAX_N];
    modified_upper[0] = upper[0] as f64 / diagonal[0] as f64;
    modified_rhs[0] = rhs[0] as f64 / diagonal[0] as f64;
    for row in 1..n {
        let pivot = diagonal[row] as f64 - lower[row] as f64 * modified_upper[row - 1];
        if row + 1 < n { modified_upper[row] = upper[row] as f64 / pivot; }
        modified_rhs[row] = (rhs[row] as f64 - lower[row] as f64 * modified_rhs[row - 1]) / pivot;
    }
    solution[n - 1] = modified_rhs[n - 1];
    for row in (0..n - 1).rev() {
        solution[row] = modified_rhs[row] - modified_upper[row] * solution[row + 1];
    }
    let bytes = std::slice::from_raw_parts_mut(output, output_bytes);
    for row in 0..n { put_f64_le(bytes, row * 8, solution[row]); }
    output_bytes as i64
}
