const INVALID_RESULT: i64 = -1;
const CAPACITY_ERROR: i64 = -2;
const HALF_STEP_LIMIT: f64 = 4_503_599_627_370_496.0;
const MAX_TICK_MAGNITUDE: i64 = 2_251_799_813_685_248;

fn finite_matrix(matrix: &[[f64; 6]; 5], n: usize) -> bool {
    for row in 0..n {
        for col in 0..=n {
            if !matrix[row][col].is_finite() { return false; }
        }
    }
    true
}

fn simplify(matrix: &mut [[f64; 6]; 5], n: usize) -> bool {
    if n < 2 || matrix[0][0] == 0.0 { return false; }
    let cols = n + 1;
    for row in 0..n {
        let magnitude = matrix[row][0];
        if magnitude != 0.0 {
            for col in 0..cols { matrix[row][col] /= magnitude; }
        }
    }
    if !finite_matrix(matrix, n) { return false; }

    let first_row = matrix[0];
    let mut first_column = [0.0f64; 5];
    for row in 1..n {
        if matrix[row][0] != 0.0 {
            for col in 0..cols { matrix[row][col] = first_row[col] - matrix[row][col]; }
        }
    }
    if !finite_matrix(matrix, n) { return false; }
    if cols != 3 {
        let mut next = [[0.0f64; 6]; 5];
        for row in 1..n {
            first_column[row - 1] = matrix[row][0];
            for col in 1..cols { next[row - 1][col - 1] = matrix[row][col]; }
        }
        if !simplify(&mut next, n - 1) { return false; }
        for col in 0..cols { matrix[0][col] = first_row[col]; }
        for row in 1..n {
            matrix[row][0] = first_column[row - 1];
            for col in 1..cols { matrix[row][col] = next[row - 1][col - 1]; }
        }
    }
    finite_matrix(matrix, n)
}

fn round_ticks(value: f64) -> Option<i64> {
    let scaled = value * 100_000.0;
    if !scaled.is_finite() || scaled <= -HALF_STEP_LIMIT || scaled >= HALF_STEP_LIMIT { return None; }
    let lower = scaled.floor();
    let midpoint = lower + 0.5;
    let exact_side = value.mul_add(100_000.0, -midpoint);
    if !exact_side.is_finite() { return None; }
    let mut rounded = lower as i64;
    if exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0) { rounded += 1; }
    if rounded < -MAX_TICK_MAGNITUDE || rounded > MAX_TICK_MAGNITUDE { return None; }
    let rounded_value = rounded as f64 / 100_000.0;
    let projected = rounded_value * 100_000.0;
    if !projected.is_finite() { return None; }
    let projected_lower = projected.floor();
    let projected_midpoint = projected_lower + 0.5;
    let mut ticks = projected_lower as i64;
    if projected > projected_midpoint ||
        (projected == projected_midpoint && ticks % 2 != 0) { ticks += 1; }
    if ticks < -MAX_TICK_MAGNITUDE || ticks > MAX_TICK_MAGNITUDE { return None; }
    Some(ticks)
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn simultaneous_linear_equation_solver(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=31).contains(&length) { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(1..=5).contains(&n_value) { return INVALID_RESULT; }
    let n = n_value as usize;
    if length != 1 + n * (n + 1) { return INVALID_RESULT; }
    let mut matrix = [[0.0f64; 6]; 5];
    let mut has_zero = false;
    for row in 0..n {
        for col in 0..=n {
            let raw = values[1 + row * (n + 1) + col];
            if !(-100_000..=100_000).contains(&raw) { return INVALID_RESULT; }
            matrix[row][col] = raw as f64 / 1_000.0;
            has_zero |= raw == 0;
        }
    }
    if n == 1 {
        if matrix[0][0] == 0.0 { return INVALID_RESULT; }
    } else {
        if has_zero {
            let full_row = (0..n).find(|&row| (0..=n).all(|col| matrix[row][col] != 0.0));
            let Some(full_row) = full_row else { return INVALID_RESULT; };
            if full_row != 0 {
                let saved = matrix[full_row];
                for row in (1..=full_row).rev() { matrix[row] = matrix[row - 1]; }
                matrix[0] = saved;
            }
        }
        if !simplify(&mut matrix, n) { return INVALID_RESULT; }
    }

    let mut solutions = [0.0f64; 5];
    for row in (0..n).rev() {
        if matrix[row][row] == 0.0 { return INVALID_RESULT; }
        let mut value = matrix[row][n];
        for col in row + 1..n { value -= matrix[row][col] * solutions[col]; }
        value /= matrix[row][row];
        if !value.is_finite() { return INVALID_RESULT; }
        solutions[row] = value;
    }
    let needed = 8 + 8 * n;
    let mut buffer = [0u8; 48];
    write_i64_le(&mut buffer, 0, n_value);
    for i in 0..n {
        let Some(ticks) = round_ticks(solutions[i]) else { return INVALID_RESULT; };
        write_i64_le(&mut buffer, 8 + 8 * i, ticks);
    }
    if output.is_null() || capacity < needed { return CAPACITY_ERROR; }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, needed);
    needed as i64
}
