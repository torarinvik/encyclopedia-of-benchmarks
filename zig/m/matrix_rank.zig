const MATRIX_RANK_EPSILON: f64 = 1e-10;

fn matrixRankIsZero(value: f64) bool {
    const magnitude = if (value < 0.0) -value else value;
    return magnitude < MATRIX_RANK_EPSILON;
}

export fn matrix_rank(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > 66) return -1;
    const input = values.?;
    const rows_value = input[0];
    const cols_value = input[1];
    if (rows_value < 1 or rows_value > 8 or cols_value < 1 or cols_value > 8) return -1;

    const rows: usize = @intCast(rows_value);
    const cols: usize = @intCast(cols_value);
    const cells = rows * cols;
    if (length != 2 + cells) return -1;

    var matrix: [64]f64 = @splat(0.0);
    var row_marked: [8]bool = @splat(false);
    for (0..cells) |index| {
        const cell = input[2 + index];
        if (cell != 0 and cell != 1) return -1;
        matrix[index] = @floatFromInt(cell);
    }

    var rank: i64 = 0;
    for (0..cols) |col| {
        var pivot_row = rows;
        for (0..rows) |row| {
            if (!row_marked[row] and !matrixRankIsZero(matrix[row * cols + col])) {
                pivot_row = row;
                break;
            }
        }
        if (pivot_row == rows) continue;

        rank += 1;
        row_marked[pivot_row] = true;
        const pivot_value = matrix[pivot_row * cols + col];
        for (col + 1..cols) |next_col| {
            matrix[pivot_row * cols + next_col] /= pivot_value;
        }
        for (0..rows) |other_row| {
            if (other_row == pivot_row) continue;
            const factor = matrix[other_row * cols + col];
            if (!matrixRankIsZero(factor)) {
                for (col + 1..cols) |next_col| {
                    matrix[other_row * cols + next_col] -=
                        matrix[pivot_row * cols + next_col] * factor;
                }
            }
        }
    }
    return rank;
}
