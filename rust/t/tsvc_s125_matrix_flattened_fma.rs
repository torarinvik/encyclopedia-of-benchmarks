/// Clean-room port of TSVC s125; see the package README for provenance and rights.
#[no_mangle]
pub extern "C" fn tsvc_s125_matrix_flattened_fma(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_N: usize = 8;
    const MAX_CELLS: usize = MAX_N * MAX_N;
    if input.is_null() || length < 4 || length > 1 + 3 * MAX_CELLS { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    let cells = n * n;
    if length != 1 + 3 * cells { return -1; }
    let mut aa = [0i64; MAX_CELLS];
    let mut bb = [0i64; MAX_CELLS];
    let mut cc = [0i64; MAX_CELLS];
    let mut result = [0i64; MAX_CELLS];
    for i in 0..cells {
        aa[i] = values[1 + i];
        bb[i] = values[1 + cells + i];
        cc[i] = values[1 + 2 * cells + i];
        if !(-100..=100).contains(&aa[i]) || !(-100..=100).contains(&bb[i]) ||
            !(-100..=100).contains(&cc[i]) { return -1; }
    }
    let output_bytes = 8 * cells;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut k = 0;
    for _row in 0..n {
        for _column in 0..n {
            result[k] = aa[k] + bb[k] * cc[k];
            k += 1;
        }
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for (i, &value) in result[..cells].iter().enumerate() {
        out[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    cells as i64
}
