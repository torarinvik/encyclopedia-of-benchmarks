const MAX_DIMENSION: usize = 8;
const MAX_MATRIX_MICRO: i64 = 1_000_000_000;
const MAX_VECTOR_MICRO: i64 = 1_000_000_000;
const MAX_SPECTRAL_MICRO: i64 = 1_000_000_000;
const MAX_ITERATIONS: i64 = 1000;

#[no_mangle]
pub unsafe extern "C" fn chebyshev_iteration(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if values[0] < 1 || values[0] as usize > MAX_DIMENSION { return -1; }
    let n = values[0] as usize;
    if length != 1 + n * n + 2 * n + 4 { return -1; }
    let matrix_end = 1 + n * n;
    let vector_end = matrix_end + 2 * n;
    let mut matrix = [0.0_f64; MAX_DIMENSION * MAX_DIMENSION];
    let mut b = [0.0_f64; MAX_DIMENSION];
    let mut x = [0.0_f64; MAX_DIMENSION];
    let mut residual = [0.0_f64; MAX_DIMENSION];
    let mut direction = [0.0_f64; MAX_DIMENSION];
    for index in 0..n * n {
        let value = values[1 + index];
        if !(-MAX_MATRIX_MICRO..=MAX_MATRIX_MICRO).contains(&value) { return -1; }
        matrix[index] = value as f64 / 1_000_000.0;
    }
    for index in 0..n {
        let rhs = values[matrix_end + index];
        let guess = values[matrix_end + n + index];
        if !(-MAX_VECTOR_MICRO..=MAX_VECTOR_MICRO).contains(&rhs)
            || !(-MAX_VECTOR_MICRO..=MAX_VECTOR_MICRO).contains(&guess) { return -1; }
        b[index] = rhs as f64 / 1_000_000.0;
        x[index] = guess as f64 / 1_000_000.0;
    }
    let min_micro = values[vector_end];
    let max_micro = values[vector_end + 1];
    let iterations = values[vector_end + 2];
    let tolerance_micro = values[vector_end + 3];
    if min_micro < 1 || max_micro <= min_micro || max_micro > MAX_SPECTRAL_MICRO
        || !(1..=MAX_ITERATIONS).contains(&iterations)
        || !(1..=MAX_VECTOR_MICRO).contains(&tolerance_micro) { return -1; }
    let min_eigenvalue = min_micro as f64 / 1_000_000.0;
    let max_eigenvalue = max_micro as f64 / 1_000_000.0;
    let tolerance = tolerance_micro as f64 / 1_000_000.0;
    let output_bytes = n * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }

    for row in 0..n {
        let mut product = 0.0;
        for column in 0..n { product += matrix[row * n + column] * x[column]; }
        residual[row] = b[row] - product;
    }
    let d = (max_eigenvalue + min_eigenvalue) / 2.0;
    let c = (max_eigenvalue - min_eigenvalue) / 2.0;
    let mut alpha = 0.0;
    let mut alpha_previous = 0.0;
    for iteration in 0..iterations {
        let mut squares = 0.0;
        for item in 0..n { squares += residual[item] * residual[item]; }
        if squares.sqrt() < tolerance { break; }
        if iteration == 0 {
            alpha = 1.0 / d;
            direction[..n].copy_from_slice(&residual[..n]);
        } else {
            let half_step = c * alpha_previous / 2.0;
            let beta = half_step * half_step;
            alpha = 1.0 / (d - beta / alpha_previous);
            let scale = beta / alpha_previous;
            for item in 0..n { direction[item] = residual[item] + scale * direction[item]; }
        }
        for item in 0..n { x[item] += alpha * direction[item]; }
        for row in 0..n {
            let mut product = 0.0;
            for column in 0..n { product += matrix[row * n + column] * x[column]; }
            residual[row] = b[row] - product;
        }
        alpha_previous = alpha;
    }
    let output = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..n { output[index * 8..index * 8 + 8].copy_from_slice(&x[index].to_le_bytes()); }
    output_bytes as i64
}
