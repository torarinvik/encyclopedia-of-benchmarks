const MAX_INPUT_LENGTH: usize = 66;
const MATRIX_RANK_EPSILON: f64 = 1e-10;

fn matrix_rank_is_zero(value: f64) -> bool {
    let magnitude = if value < 0.0 { -value } else { value };
    magnitude < MATRIX_RANK_EPSILON
}

#[no_mangle]
pub unsafe extern "C" fn matrix_rank(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let rows_value = input[0];
    let cols_value = input[1];
    if !(1..=8).contains(&rows_value) || !(1..=8).contains(&cols_value) { return -1; }

    let rows = rows_value as usize;
    let cols = cols_value as usize;
    let cells = rows * cols;
    if length != 2 + cells { return -1; }

    let mut matrix = [0.0f64; 64];
    let mut row_marked = [false; 8];
    for index in 0..cells {
        let cell = input[2 + index];
        if cell != 0 && cell != 1 { return -1; }
        matrix[index] = cell as f64;
    }

    let mut rank = 0i64;
    for col in 0..cols {
        let mut pivot_row = rows;
        for row in 0..rows {
            if !row_marked[row] && !matrix_rank_is_zero(matrix[row * cols + col]) {
                pivot_row = row;
                break;
            }
        }
        if pivot_row == rows { continue; }

        rank += 1;
        row_marked[pivot_row] = true;
        let pivot_value = matrix[pivot_row * cols + col];
        for next_col in col + 1..cols {
            matrix[pivot_row * cols + next_col] /= pivot_value;
        }
        for other_row in 0..rows {
            if other_row == pivot_row { continue; }
            let factor = matrix[other_row * cols + col];
            if !matrix_rank_is_zero(factor) {
                for next_col in col + 1..cols {
                    matrix[other_row * cols + next_col] -= matrix[pivot_row * cols + next_col] * factor;
                }
            }
        }
    }
    rank
}
