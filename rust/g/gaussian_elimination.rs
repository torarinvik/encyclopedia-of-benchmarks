fn put_f64_le(out: &mut [u8], offset: usize, value: f64) {
    out[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn gaussian_elimination(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=8).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != 1 + n * n + n { return -1; }
    let mut matrix = [[0.0_f32; 9]; 8];
    for row in 0..n {
        for col in 0..n {
            let value = values[1 + row * n + col];
            if (row == col && value != 32) || (row != col && value != 0 && value != -1) { return -1; }
            if (row + 1 < col || col + 1 < row) && value != 0 { return -1; }
            if row != col && value != values[1 + col * n + row] { return -1; }
            matrix[row][col] = value as f32;
        }
        let rhs = values[1 + n * n + row];
        if !(-100..=100).contains(&rhs) { return -1; }
        matrix[row][n] = rhs as f32;
    }
    if output.is_null() || capacity < n * 8 { return -2; }

    // Preserve the pinned Rust implementation's f32 forward/backward updates.
    for i in 0..n.saturating_sub(1) {
        for j in i..n.saturating_sub(1) {
            if matrix[i][i] != 0.0 {
                let factor = matrix[j + 1][i] / matrix[i][i];
                for k in i..=n { matrix[j + 1][k] -= factor * matrix[i][k]; }
            }
        }
    }
    for i in (1..n).rev() {
        if matrix[i][i] != 0.0 {
            for j in (1..=i).rev() {
                let factor = matrix[j - 1][i] / matrix[i][i];
                for k in (0..=n).rev() { matrix[j - 1][k] -= factor * matrix[i][k]; }
            }
        }
    }
    let bytes = std::slice::from_raw_parts_mut(output, n * 8);
    for row in 0..n {
        put_f64_le(bytes, row * 8, (matrix[row][n] / matrix[row][row]) as f64);
    }
    (n * 8) as i64
}
