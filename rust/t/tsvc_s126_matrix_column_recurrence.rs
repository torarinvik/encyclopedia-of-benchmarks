/// Clean-room port of TSVC s126; see the package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s126_matrix_column_recurrence(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 6;
    const MAX_CELLS: usize = MAX_N * MAX_N;
    if input.is_null() || length < 13 || length > 1 + 3 * MAX_CELLS { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 2 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    let cells = n * n;
    if length != 1 + 3 * cells { return -1; }
    let mut coefficients = [0i64; MAX_CELLS];
    let mut c_matrix = [0i64; MAX_CELLS];
    let mut b_matrix = [0i64; MAX_CELLS];
    for i in 0..cells {
        coefficients[i] = values[1 + i];
        c_matrix[i] = values[1 + cells + i];
        b_matrix[i] = values[1 + 2 * cells + i];
        if !(-100..=100).contains(&coefficients[i]) ||
            !(-100..=100).contains(&c_matrix[i]) || !(-100..=100).contains(&b_matrix[i]) { return -1; }
    }
    let output_bytes = 8 * cells;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut k = 1;
    for i in 0..n {
        for j in 1..n {
            let target = j * n + i;
            b_matrix[target] = b_matrix[target - n] + coefficients[k - 1] * c_matrix[target];
            k += 1;
        }
        k += 1;
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for (i, &value) in b_matrix[..cells].iter().enumerate() {
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    cells as i64
}
