const MAX_DIMENSION: usize = 8;
const MAX_ENTRY_MICRO: i64 = 1_000_000_000;
const SCALE: f64 = 1_000_000.0;
const TOLERANCE: f64 = 1.0e-10;
const MAX_ITERATIONS: usize = 1000;

fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bits = value.to_bits();
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn conjugate_gradient(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > 1 + MAX_DIMENSION * MAX_DIMENSION + MAX_DIMENSION { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 1 || input[0] as usize > MAX_DIMENSION { return -1; }
    let n = input[0] as usize;
    if length != 1 + n * n + n { return -1; }
    let vector_offset = 1 + n * n;
    let mut matrix = [0.0_f64; MAX_DIMENSION * MAX_DIMENSION];
    let mut rhs = [0.0_f64; MAX_DIMENSION];
    let mut solution = [0.0_f64; MAX_DIMENSION];
    let mut residual = [0.0_f64; MAX_DIMENSION];
    let mut direction = [0.0_f64; MAX_DIMENSION];
    let mut product = [0.0_f64; MAX_DIMENSION];
    for &value in &input[1..] {
        if value < -MAX_ENTRY_MICRO || value > MAX_ENTRY_MICRO { return -1; }
    }
    for row in 0..n {
        let diagonal = input[1 + row * n + row];
        if diagonal <= 0 { return -1; }
        let mut off_diagonal_sum = 0_i64;
        for column in 0..n {
            let entry = input[1 + row * n + column];
            if entry != input[1 + column * n + row] { return -1; }
            if column != row { off_diagonal_sum += entry.abs(); }
            matrix[row * n + column] = entry as f64 / SCALE;
        }
        if diagonal <= off_diagonal_sum { return -1; }
        rhs[row] = input[vector_offset + row] as f64 / SCALE;
        residual[row] = rhs[row];
        direction[row] = rhs[row];
    }
    let output_bytes = n * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    let mut residual_squared = 0.0;
    for index in 0..n { residual_squared += residual[index] * residual[index]; }
    for _ in 0..MAX_ITERATIONS {
        if residual_squared <= TOLERANCE * TOLERANCE { break; }
        for row in 0..n {
            product[row] = 0.0;
            for column in 0..n { product[row] += matrix[row * n + column] * direction[column]; }
        }
        let mut denominator = 0.0;
        for index in 0..n { denominator += direction[index] * product[index]; }
        if denominator <= 0.0 { return -1; }
        let alpha = residual_squared / denominator;
        for index in 0..n {
            solution[index] += alpha * direction[index];
            residual[index] -= alpha * product[index];
        }
        let mut next_residual_squared = 0.0;
        for index in 0..n { next_residual_squared += residual[index] * residual[index]; }
        if next_residual_squared <= TOLERANCE * TOLERANCE {
            residual_squared = next_residual_squared;
            break;
        }
        let beta = next_residual_squared / residual_squared;
        for index in 0..n { direction[index] = residual[index] + beta * direction[index]; }
        residual_squared = next_residual_squared;
    }
    for index in 0..n { write_f64_le(output, index * 8, solution[index]); }
    output_bytes as i64
}
