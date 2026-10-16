const INVALID_RESULT: f64 = -1.0e300;

fn finite_tableau(tableau: &[[f64; 16]; 8], rows: usize, cols: usize) -> bool {
    for row in 0..rows {
        for col in 0..cols {
            if !tableau[row][col].is_finite() { return false; }
        }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn simplex(input: *const i64, length: usize) -> f64 {
    if input.is_null() || !(4..=132).contains(&length) { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_vars_value, n_artificial_value, n_rows_value, n_cols_value) =
        (values[0], values[1], values[2], values[3]);
    if !(2..=4).contains(&n_vars_value) || !(0..=2).contains(&n_artificial_value)
        || !(3..=8).contains(&n_rows_value) || n_cols_value < n_vars_value + n_artificial_value + 1
        || n_cols_value > 16 {
        return INVALID_RESULT;
    }
    let (mut rows, mut cols, mut artificial) =
        (n_rows_value as usize, n_cols_value as usize, n_artificial_value as usize);
    if length != 4 + rows * cols { return INVALID_RESULT; }
    let mut tableau = [[0.0f64; 16]; 8];
    for row in 0..rows {
        for col in 0..cols {
            tableau[row][col] = values[4 + row * cols + col] as f64 / 1_000_000.0;
        }
        if tableau[row][cols - 1] < 0.0 { return INVALID_RESULT; }
    }

    let mut phase_one = artificial != 0;
    let mut finished = false;
    for _ in 0..100 {
        if finished {
            let result = tableau[0][cols - 1].abs();
            return if result.is_finite() { result } else { INVALID_RESULT };
        }
        let stages = if phase_one { 2 } else { 1 };
        let sign = if phase_one { 1.0 } else { -1.0 };
        let mut pivot_col = 0usize;
        let mut best = sign * tableau[0][0];
        for col in 1..cols - 1 {
            let score = sign * tableau[0][col];
            if score > best { best = score; pivot_col = col; }
        }
        if best <= 0.0 {
            if phase_one {
                let first_artificial = cols - artificial - 1;
                let mut compacted = [[0.0f64; 16]; 8];
                for row in 1..rows {
                    let mut new_col = 0usize;
                    for col in 0..cols {
                        if col >= first_artificial && col < cols - 1 { continue; }
                        compacted[row - 1][new_col] = tableau[row][col];
                        new_col += 1;
                    }
                }
                rows -= 1;
                cols -= artificial;
                artificial = 0;
                tableau = compacted;
                phase_one = false;
            } else {
                finished = true;
            }
            continue;
        }

        let mut found = false;
        let mut pivot_row = 0usize;
        let mut best_ratio = 0.0;
        for row in stages..rows {
            let divisor = tableau[row][pivot_col];
            if divisor > 0.0 {
                let ratio = tableau[row][cols - 1] / divisor;
                if !ratio.is_finite() { return INVALID_RESULT; }
                if !found || ratio < best_ratio {
                    found = true;
                    best_ratio = ratio;
                    pivot_row = row;
                }
            }
        }
        if !found { return INVALID_RESULT; }

        let pivot = tableau[pivot_row][pivot_col];
        let mut normalized = [0.0f64; 16];
        for col in 0..cols { normalized[col] = tableau[pivot_row][col] / pivot; }
        let mut column_values = [0.0f64; 8];
        for row in 0..rows { column_values[row] = tableau[row][pivot_col]; }
        for row in 0..rows {
            let coefficient = column_values[row];
            for col in 0..cols { tableau[row][col] += -coefficient * normalized[col]; }
        }
        for col in 0..cols { tableau[pivot_row][col] = normalized[col]; }
        if !finite_tableau(&tableau, rows, cols) { return INVALID_RESULT; }
    }
    INVALID_RESULT
}
