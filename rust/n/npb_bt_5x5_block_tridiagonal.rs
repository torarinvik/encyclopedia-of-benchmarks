const BLOCK: usize = 5;
const MAX_LINE: usize = 4;
const ROW_WORDS: usize = 80;
const INVALID_RESULT: f64 = -1.0e300;

fn solve_block(matrix: &[[f64; BLOCK]; BLOCK], right: &[[f64; 6]; BLOCK]) -> Option<[[f64; 6]; BLOCK]> {
    let mut work = [[0.0; 11]; BLOCK];
    for r in 0..BLOCK {
        for c in 0..BLOCK { work[r][c] = matrix[r][c]; }
        for c in 0..6 { work[r][BLOCK + c] = right[r][c]; }
    }
    for pivot in 0..BLOCK {
        let mut best = pivot;
        for r in pivot + 1..BLOCK {
            if work[r][pivot].abs() > work[best][pivot].abs() { best = r; }
        }
        if work[best][pivot] == 0.0 { return None; }
        work.swap(pivot, best);
        let divisor = work[pivot][pivot];
        for c in pivot..11 { work[pivot][c] /= divisor; }
        for r in 0..BLOCK {
            if r == pivot { continue; }
            let factor = work[r][pivot];
            for c in pivot..11 { work[r][c] -= factor * work[pivot][c]; }
        }
    }
    let mut answer = [[0.0; 6]; BLOCK];
    for r in 0..BLOCK { for c in 0..6 { answer[r][c] = work[r][BLOCK + c]; } }
    Some(answer)
}

#[no_mangle]
pub unsafe extern "C" fn npb_bt_5x5_block_tridiagonal(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 1 || length > 1 + ROW_WORDS * MAX_LINE { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    if !(2..=MAX_LINE as i64).contains(&values[0]) { return INVALID_RESULT; }
    let n = values[0] as usize;
    if length != 1 + ROW_WORDS * n { return INVALID_RESULT; }

    let mut lower = [[[0.0; BLOCK]; BLOCK]; MAX_LINE];
    let mut diagonal = [[[0.0; BLOCK]; BLOCK]; MAX_LINE];
    let mut upper = [[[0.0; BLOCK]; BLOCK]; MAX_LINE];
    let mut rhs = [[0.0; BLOCK]; MAX_LINE];
    for row in 0..n {
        let mut cursor = 1 + ROW_WORDS * row;
        for which in 0..3 {
            for r in 0..BLOCK { for c in 0..BLOCK {
                let value = values[cursor]; cursor += 1;
                if which == 1 {
                    if r == c {
                        if !(40..=64).contains(&value) { return INVALID_RESULT; }
                    } else if !(-2..=2).contains(&value) { return INVALID_RESULT; }
                    diagonal[row][r][c] = value as f64;
                } else {
                    if !(-2..=2).contains(&value) { return INVALID_RESULT; }
                    if which == 0 { lower[row][r][c] = value as f64; }
                    else { upper[row][r][c] = value as f64; }
                }
            }}
        }
        for r in 0..BLOCK {
            let value = values[cursor]; cursor += 1;
            if !(-1000..=1000).contains(&value) { return INVALID_RESULT; }
            rhs[row][r] = value as f64;
        }
        if row == 0 && lower[row].iter().flatten().any(|&value| value != 0.0) { return INVALID_RESULT; }
        if row + 1 == n && upper[row].iter().flatten().any(|&value| value != 0.0) { return INVALID_RESULT; }
        for r in 0..BLOCK {
            let mut off_diagonal = 0.0;
            for c in 0..BLOCK {
                if r != c { off_diagonal += diagonal[row][r][c].abs(); }
                off_diagonal += lower[row][r][c].abs() + upper[row][r][c].abs();
            }
            if diagonal[row][r][r] <= off_diagonal { return INVALID_RESULT; }
        }
    }

    let mut modified_upper = [[[0.0; BLOCK]; BLOCK]; MAX_LINE];
    let mut modified_rhs = [[0.0; BLOCK]; MAX_LINE];
    for row in 0..n {
        let mut schur = diagonal[row];
        let mut reduced = rhs[row];
        if row > 0 {
            for r in 0..BLOCK {
                for c in 0..BLOCK {
                    for k in 0..BLOCK { schur[r][c] -= lower[row][r][k] * modified_upper[row - 1][k][c]; }
                }
                for k in 0..BLOCK { reduced[r] -= lower[row][r][k] * modified_rhs[row - 1][k]; }
            }
        }
        let mut right = [[0.0; 6]; BLOCK];
        for r in 0..BLOCK {
            for c in 0..BLOCK { right[r][c] = upper[row][r][c]; }
            right[r][5] = reduced[r];
        }
        let Some(solved) = solve_block(&schur, &right) else { return INVALID_RESULT; };
        for r in 0..BLOCK {
            modified_rhs[row][r] = solved[r][5];
            for c in 0..BLOCK { modified_upper[row][r][c] = solved[r][c]; }
        }
    }
    let mut solution = [[0.0; BLOCK]; MAX_LINE];
    solution[n - 1] = modified_rhs[n - 1];
    for row in (0..n - 1).rev() {
        for r in 0..BLOCK {
            solution[row][r] = modified_rhs[row][r];
            for c in 0..BLOCK { solution[row][r] -= modified_upper[row][r][c] * solution[row + 1][c]; }
        }
    }
    let mut checksum = 0.0;
    for row in 0..n { for r in 0..BLOCK { checksum += (row * BLOCK + r + 1) as f64 * solution[row][r]; } }
    if checksum.is_finite() { checksum } else { INVALID_RESULT }
}
