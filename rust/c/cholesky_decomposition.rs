const MAX_DIMENSION: usize = 6;
const MAX_ENTRY_MICRO: i64 = 1_000_000_000;

fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bits = value.to_bits();
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn cholesky_decomposition(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > 1 + MAX_DIMENSION * MAX_DIMENSION { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 1 || input[0] as usize > MAX_DIMENSION { return -1; }
    let n = input[0] as usize;
    if length != 1 + n * n { return -1; }

    let mut matrix = [0.0_f64; MAX_DIMENSION * MAX_DIMENSION];
    let mut lower = [0.0_f64; MAX_DIMENSION * MAX_DIMENSION];
    for index in 0..n * n {
        let scaled = input[index + 1];
        if !(-MAX_ENTRY_MICRO..=MAX_ENTRY_MICRO).contains(&scaled) { return -1; }
        matrix[index] = scaled as f64 / 1_000_000.0;
    }
    for row in 0..n {
        for column in 0..n {
            let left = matrix[row * n + column];
            let right = matrix[column * n + row];
            if (left - right).abs() > 1.0e-8 + 1.0e-5 * right.abs() { return -1; }
        }
    }

    for row in 0..n {
        for column in 0..=row {
            let mut sum = 0.0;
            for index in 0..column {
                sum += lower[row * n + index] * lower[column * n + index];
            }
            let residual = matrix[row * n + column] - sum;
            if row == column {
                if residual <= 0.0 { return -1; }
                lower[row * n + column] = residual.sqrt();
            } else {
                lower[row * n + column] = residual / lower[column * n + column];
            }
        }
    }

    let output_bytes = n * n * 8;
    if output_bytes > output_capacity || output.is_null() { return -2; }
    for index in 0..n * n { write_f64_le(output, index * 8, lower[index]); }
    output_bytes as i64
}
